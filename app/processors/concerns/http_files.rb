require 'timeout'
require 'audio_monster'
require 'net/http'
require 'rest_client'

module HttpFiles
  def http_download_file(uri, limit = 10)
    # You should choose better exception.
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 1800

    if uri.instance_of? URI::HTTPS
      # puts "ssl: #{uri}"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req = Net::HTTP::Get.new(uri.request_uri)
    temp_file = nil
    redirect_url = nil

    http.request(req) do |response|
      case response
      when Net::HTTPSuccess
        # puts "success: #{uri}"
        # puts "Content-Disposition: #{response['Content-Disposition']}"
        file_name = uri.path.split("/").last
        temp_file = AudioMonster.create_temp_file(file_name)
        response.read_body do |segment|
          temp_file.write(segment)
        end
        temp_file.flush
      when Net::HTTPRedirection
        redirect_url = response['location']
        # puts "redirect: #{redirect_url}"
      else
        response.error!
      end
    end

    if redirect_url
      # this is imperfect, but deals with odd case where we have spaces in some redirects
      redirect_url = URI.escape(redirect_url) if redirect_url =~ /\s+/
      http_download_file(URI.parse(redirect_url), limit - 1)
    else
      temp_file
    end
  end

  def http_execute(url, data, options={})
    no_retry = !!options[:no_retry]

    if no_retry
      retry_max  = 0
      retry_wait = 0
    else
      retry_max  = options.key?(:retry_max) ? options[:retry_max].to_i : 6
      retry_wait = options.key?(:retry_wait) ? options[:retry_max].to_i : 10
    end

    headers      = options[:headers] || {}
    method       = options[:method] || :post
    content_type = options[:content_type] || :json

    timeout      = options.key?(:timeout) ? options[:timeout].to_i : 30
    open_timeout = options.key?(:open_timeout) ? options[:open_timeout].to_i : 10

    request_options = {
      :method       =>method,
      :url          =>url,
      :timeout      =>timeout,
      :open_timeout =>open_timeout
    }

    if [:post, :put, :patch].include?(method)
      headers[:content_type] = content_type
      request_options[:payload] = data
    elsif data.is_a?(Hash)
      headers[:params] = data
    end

    request_options[:headers] = headers

    retry_count = 0
    result = false
    err = nil
    response = nil

    while (!result && (retry_count <= retry_max)) do

      begin
        Timeout.timeout(open_timeout + timeout + 10) do
          response = RestClient::Request.execute(request_options)
        end
        if response && (200..207).include?(response.code)
          result = true
        else
          raise "http_execute response code: #{response.code}): response: #{response.inspect}"
        end
      rescue StandardError=>err
        #need to do something to retry this - use new a13g func for this.
        logger.error "http_execute retrycount(#{retry_count}): error: #{err.message}"
        retry_count = retry_count + 1
        sleep(retry_wait)
      end

    end

    if !result
      if err
        raise err
      else
        raise "http fail, no more retries"
      end
    end

    response
  end
end

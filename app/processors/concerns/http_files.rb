# encoding: utf-8

require 'timeout'
require 'audio_monster'
require 'net/http'
require 'excon'

module HttpFiles

  def http_upload_file(uri, local_file, options={})
    raise NotImplementedError.new('Upload via http not available yet.')
  end

  def http_download_file(uri, limit = 10)
    temp_file = nil
    try_count = 0
    file_downloaded = false

    prior_remaining, prior_total = 0
    streamer = lambda do |chunk, remaining_bytes, total_bytes|
      if (remaining_bytes > prior_remaining) || (total_bytes != prior_total) || !temp_file
        close_temp_file(temp_file)
        temp_file = AudioMonster.create_temp_file(uri.to_s)
      end

      prior_remaining = remaining_bytes
      prior_total = total_bytes
      temp_file.write(chunk)
    end

    while !file_downloaded && try_count < limit
      try_count += 1
      begin

        close_temp_file(temp_file)

        Excon.get(uri.to_s, {
          idempotent: false,
          retry_limit: 0,
          ssl_verify_peer: false,
          response_block: streamer,
          middlewares: Excon.defaults[:middlewares] + [Excon::Middleware::RedirectFollower]
        })

        temp_file.fsync()
        file_downloaded = true
      rescue StandardError => err
        logger.error "File failed to be retrieved: '#{uri}': #{err.message}"
      end
      sleep(1)
    end

    raise "HTTP Download #{uri}: did not complete" unless file_downloaded

    raise "HTTP Download #{uri}: #{temp_file.size} is not the expected size: #{prior_total}" if temp_file.size != prior_total

    raise "HTTP Download #{uri}: Zero length file downloaded" if temp_file.size == 0

    temp_file
  end

  def close_temp_file(temp_file)
    if temp_file
      temp_file.close
      File.unlink(temp_file)
    end
  rescue
    nil
  end

  def http_execute(uri, data, options={})
    connection = Excon.new(uri.to_s)
    request = {
      method: options[:method] || :post,
      headers: options[:headers] || {},
      expects: (200..207).to_a,
      idempotent: !options[:no_retry],
      retry_limit: (options.key?(:retry_max) ? options[:retry_max].to_i : 6),
      ssl_verify_peer: false
    }

    if [:post, :put, :patch].include?(request[:method])
      request[:headers]['Content-Type'] = mime_type_string(options[:content_type] || :json)
      request[:body] = data
    elsif data.is_a?(Hash)
      headers[:query] = data
    end

    connection.request(request)
  end

  def mime_type_string(type)
    case type
    when :json
      'application/json; charset=utf-8'
    when :form
      'application/x-www-form-urlencoded'
    else
      'text/html; charset=utf-8'
    end
  end
end

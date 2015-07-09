# encoding: utf-8

require 'excon'

module HttpCallback
  def http_callback(web_hook)
    http_execute(web_hook[:url], web_hook[:message])
  end

  alias_method :https_callback, :http_callback

  def http_execute(uri, data, options={})
    connection = Excon.new(
      uri.to_s,
      ssl_verify_peer: ENV['SSL_VERIFY_PEER'],
      omit_default_port: true
    )
    request = {
      method: options[:method] || :post,
      headers: options[:headers] || {},
      expects: (200..207).to_a,
      idempotent: !options[:no_retry],
      retry_limit: (options.key?(:retry_max) ? options[:retry_max].to_i : 6),
      middlewares: Excon.defaults[:middlewares] + [Excon::Middleware::RedirectFollower]
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

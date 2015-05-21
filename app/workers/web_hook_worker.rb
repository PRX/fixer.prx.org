# encoding: utf-8

require 'base_worker'
require 'excon'

class WebHookWorker < BaseWorker

  queue_as :fixer_p2

  def perform(web_hook)
    logger.info "WebHookWorker start: #{web_hook.inspect}"

    web_hook = JSON.parse(web_hook).with_indifferent_access
    web_hook = web_hook[:web_hook]

    uri = URI.parse(web_hook[:url])
    if uri.scheme[0,4] == 'http'
      http_execute(web_hook[:url], web_hook[:message], content_type: :json)
    elsif uri.scheme == 'mailto'
      WebHookMailer.notification(web_hook).deliver
    elsif uri.scheme == 'sqs'
      # TODO
      raise "Currently SQS is unsupported for web hooks, but is on the way!"
    else
      raise "Unsupported web hook URI scheme: #{uri.scheme} for #{uri.to_s}"
    end

    publish_webhook_update(web_hook[:id], true)
  rescue StandardError => err
    logger.error "WebHookWorker web_hook: #{web_hook.inspect} rescued error: #{err.class.name}:\n#{err.message}\n\t#{err.backtrace.join("\n\t")}"
    if web_hook
      publish_webhook_update(web_hook[:id], false) rescue nil
    end
  end

  def publish_webhook_update(id, complete)
    log = { web_hook: { id: id, complete: complete } }
    WebHookUpdateWorker.perform_later(log.to_json)
    log
  end

  def http_execute(uri, data, options={})
    connection = Excon.new(uri.to_s, ssl_verify_peer: false )
    request = {
      method: options[:method] || :post,
      headers: options[:headers] || {},
      expects: (200..207).to_a,
      idempotent: !options[:no_retry],
      retry_limit: (options.key?(:retry_max) ? options[:retry_max].to_i : 6)
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

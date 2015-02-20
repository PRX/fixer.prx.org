# encoding: utf-8

require 'base_worker'

class WebHookWorker < BaseWorker

  def perform(web_hook)
    web_hook = web_hook.with_indifferent_access
    logger.info "WebHookProcessor start: #{web_hook.inspect}"

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
    WebHookUpdateWorker.publish(:update, log)
    log
  end
end

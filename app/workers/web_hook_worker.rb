# encoding: utf-8

require 'base_worker'
require 'service_options'
require 'excon'

%w(http mailto sns sqs).each { |f| require "callbacks/#{f}_callback" }

class WebHookWorker < BaseWorker

  include HttpCallback
  include MailtoCallback
  include SnsCallback
  include SqsCallback

  queue_as :fixer_p2

  def perform(web_hook)
    log = nil
    logger.info "WebHookWorker start: #{web_hook.inspect}"

    web_hook = JSON.parse(web_hook).with_indifferent_access
    web_hook = web_hook[:web_hook]

    uri = URI.parse(web_hook[:url])

    # send callback based on the web hook url scheme
    send("#{uri.scheme}_callback", web_hook)

    log = publish_webhook_update(web_hook[:id], true)
    return log
  rescue StandardError => err
    logger.error "WebHookWorker web_hook: #{web_hook.inspect} rescued error: #{err.class.name}:\n#{err.message}\n\t#{err.backtrace.join("\n\t")}"
    if web_hook
      log = publish_webhook_update(web_hook[:id], false) rescue nil
    end
    log
  end

  def publish_webhook_update(id, complete)
    log = { web_hook: { id: id, complete: complete } }
    WebHookUpdateWorker.perform_later(log.to_json)
    log
  end
end

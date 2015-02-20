# encoding: utf-8

require 'base_worker'

class WebHookUpdateWorker < BaseWorker

  def perform(web_hook)
    log = log.with_indifferent_access
    web_hook_log = log[:web_hook]
    web_hook = WebHook.find_by_id(web_hook_log[:id])
    return unless web_hook

    web_hook.update_completed(web_hook_log[:complete])
  end
end

# encoding: utf-8

module MailtoCallback
  def mailto_callback(web_hook)
    WebHookMailer.notification(web_hook).deliver_now
  end
end

# Preview all emails at http://localhost:3000/rails/mailers/web_hook_mailer
class WebHookMailerPreview < ActionMailer::Preview

  def web_hook
    {
      id: '123',
      informer_id: 'abc123informer',
      informer_type: 'Job',
      informer_status: 'completed',
      message: 'The job is complete-o',
      url: 'mailto:test@prx.org'
    }
  end

  # Preview this email at http://localhost:3000/rails/mailers/web_hook_mailer/notification
  def notification
    WebHookMailer.notification(web_hook)
  end

end

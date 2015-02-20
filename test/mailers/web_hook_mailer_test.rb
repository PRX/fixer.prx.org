require 'test_helper'

class WebHookMailerTest < ActionMailer::TestCase

  let(:web_hook) do
    {
      id: '123',
      informer_id: 'abc123informer',
      informer_type: 'Job',
      informer_status: 'completed',
      message: 'The job is complete-o',
      url: 'mailto:test@prx.org'
    }
  end

  test "notification" do
    mail = WebHookMailer.notification(web_hook)
    mail.to.must_equal ['test@prx.org']
    mail.from.must_equal ['fixer@prx.org']
    mail.subject.must_equal '[FIXER] notification: completed: Job: abc123informer'
    mail.body.encoded.must_match /The job is complete-o/
  end

  test "notification with subject" do
    web_hook[:url] += '?' + {subject: "$id : $type : $status"}.to_query
    mail = WebHookMailer.notification(web_hook)
    mail.subject.must_equal 'abc123informer : Job : completed'
  end
end

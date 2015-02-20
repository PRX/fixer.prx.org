# encoding: utf-8

class ApplicationMailer < ActionMailer::Base
  self.default_url_options = { host: ENV['MAIL_HOST'] }
  default from: ENV['MAIL_FROM']
  layout 'mailer'
end

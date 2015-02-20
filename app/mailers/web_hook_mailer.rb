# encoding: utf-8

require 'uri'

class WebHookMailer < ApplicationMailer

  def notification(web_hook)
    @web_hook = web_hook.with_indifferent_access
    @message = @web_hook[:message]
    mailto_uri = URI.parse(@web_hook[:url])
    raise "Scheme is not mailto, it is: #{mailto_uri.scheme}" unless mailto_uri.scheme.to_s == 'mailto'

    mail(get_headers(mailto_uri, @web_hook))
  end

  def get_headers(uri, web_hook)
    headers = Hash[uri.headers.map { |k,v| [k.to_s.downcase.to_sym, v] }]
    headers[:content_type] = "text/html"
    headers[:return_path] = headers.delete(:from) if headers.key?(:from)
    headers[:subject] = format_subject(headers[:subject], web_hook)
    headers[:to] = uri.to
    headers
  end

  def format_subject(subject, web_hook)
    if subject.blank?
      "[FIXER] notification: #{web_hook['informer_status']}: #{web_hook['informer_type']}: #{web_hook['informer_id']}"
    else
      s = URI.decode_www_form_component(subject) || ''
      s.gsub!(/\$id/, web_hook['informer_id'])
      s.gsub!(/\$type/, web_hook['informer_type'])
      s.gsub!(/\$status/, web_hook['informer_status'])
      s
    end
  end
end

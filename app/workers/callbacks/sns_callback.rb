# encoding: utf-8

require 'fog'
require 'service_options'

module SnsCallback
  def sns_callback(web_hook)
    uri = URI.parse(web_hook[:url])
    options = sns_options(uri)

    sns = sns(options)
    destination = uri.path[1..-1]
    arn = find_or_create_topic(sns, destination)

    sns.publish(topic_arn: arn, message: web_hook[:message])
  end

  def find_or_create_topic(sns, name)
    resp = sns.create_topic(name: name)
    resp.topic_arn
  end

  def sns(options = {})
    @sns ||= Aws::SNS::Client.new(options)
  end

  def sns=(sns)
    @sns = sns
  end

  def sns_options(uri)
    so = ServiceOptions.awssdk_service_options
    so.merge(ServiceOptions.awssdk_options_for_uri(uri))
  end
end

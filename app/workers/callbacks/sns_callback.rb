# encoding: utf-8

require 'rack'
require 'aws-sdk-core'
require 'service_options'

module SnsCallback
  def sns_callback(web_hook)
    uri = URI.parse(web_hook[:url])
    options = sns_options(uri)
    params = Rack::Utils.parse_nested_query(uri.query)

    sns = sns(options)
    destination = uri.path[1..-1]
    arn = find_or_create_topic(sns, destination)

    sns.publish(message(arn, web_hook, params['worker']))
  end

  def find_or_create_topic(sns, name)
    resp = sns.create_topic(name: name)
    resp.topic_arn
  end

  def message(arn, web_hook, worker)
    msg = {
      topic_arn: arn,
      message: web_hook[:message],
      message_attributes: {}
    }
    if worker
      msg[:message_attributes]['shoryuken_class'] = {
        string_value: worker,
        data_type: 'String'
      }
    end
    msg
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

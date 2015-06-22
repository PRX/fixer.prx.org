# encoding: utf-8

require 'yaml'
require 'erb'
require 'uri'
require 'active_support/core_ext/hash/indifferent_access'
require 'system_information'

module ServiceOptions

  def self.root=(r)
    @root = r
  end

  def self.root
    @root ||= (defined?(Rails) && Rails.respond_to?(:root) && Rails.root) ||
    ENV['APP_ROOT'] ||
    File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end

  def self.file_path=(fp)
    @file_path = fp
  end

  def self.file_path
    @file_path ||= "#{root}/config/services.yml"
  end

  def self.options=(opts)
    @options = opts
  end

  def self.options
    @options ||= parse_service_options || {}
  end

  def self.service_options(service)
    service = provider_abbr_for_uri(service) if service.is_a?(URI)
    options[service].with_indifferent_access
  end

  def self.storage_options_for_uri(uri)
    options = nil
    # see if there is a user and pwd
    key      = URI.decode(uri.user) if uri.user
    secret   = URI.decode(uri.password) if uri.password
    provider = provider_for_uri(uri)
    abbr     = provider_abbr_for_uri(uri)
    if key && secret && provider && abbr
      options = {
        :provider => provider,
        "#{abbr}_access_key_id".to_sym => key,
        "#{abbr}_secret_access_key".to_sym => secret
      }.with_indifferent_access
    end
    options
  rescue
    nil
  end

  def self.awssdk_service_options
    so = ServiceOptions.service_options(:aws)
    {
      access_key_id: so[:aws_access_key_id],
      secret_access_key: so[:aws_secret_access_key]
    }
  end

  def self.awssdk_options_for_uri(uri)
    options = {}

    if uri.user && uri.password
      options[:access_key_id] = URI.decode(uri.user)
      options[:secret_access_key] = URI.decode(uri.password)
    end

    if uri.host.include?('.')
      options[:endpoint] = uri.host
    else
      options[:region] = uri.host
    end

    options
  end


  def self.parse_service_options
    so = YAML::load(ERB.new(File.read(file_path)).result).with_indifferent_access
    so[SystemInformation.env].with_indifferent_access if so
  end

  def self.provider_for_uri(u)
    case u.scheme
    when 's3' then 'AWS'
    when 'sqs' then 'AWS'
    when 'ia' then 'InternetArchive'
    else nil
    end
  end

  def self.provider_abbr_for_uri(u)
    case u.scheme
    when 's3' then :aws
    when 'sqs' then :aws
    when 'ia' then :ia
    else nil
    end
  end
end

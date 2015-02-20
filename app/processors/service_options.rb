# encoding: utf-8

require 'yaml'
require 'erb'
require 'uri'
require 'active_support/core_ext/hash/indifferent_access'

module ServiceOptions

  def self.env=(e)
    @env = e
  end

  def self.env
    @env ||= (defined?(Rails) && Rails.respond_to?(:env) && Rails.env) ||
    ENV['RAILS_ENV'] || ENV['APP_ENV'] ||
    'development'
  end

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
    service = storage_provider_abbr_for_uri(service) if service.is_a?(URI)
    options[service].with_indifferent_access
  end

  def self.options_for_uri(uri)
    options = nil
    # see if there is a user and pwd
    key      = URI.decode(uri.user) if uri.user
    secret   = URI.decode(uri.password) if uri.password
    provider = storage_provider_for_uri(uri)
    abbr     = storage_provider_abbr_for_uri(uri)
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

  def self.parse_service_options
    so = YAML::load(ERB.new(File.read(file_path)).result).with_indifferent_access
    so[env].with_indifferent_access if so
  end

  def self.storage_provider_for_uri(u)
    case u.scheme
    when 's3' then 'AWS'
    when 'ia' then 'InternetArchive'
    else nil
    end
  end

  def self.storage_provider_abbr_for_uri(u)
    case u.scheme
    when 's3' then :aws
    when 'ia' then :ia
    else nil
    end
  end
end

require 'yaml'
require 'erb'
require 'uri'
require 'active_support/core_ext/hash/indifferent_access'

module ServiceOptions

  def self.root=(r)
    @root = r
  end

  def self.root
    @root ||= (defined?(Rails) && Rails.respond_to?(:root) && Rails.root) ||
    ENV['APP_ROOT'] ||
    File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end

  def self.options=(opts)
    @options = opts
  end

  def self.options
    @options ||= parse_service_options || {}
  end

  def self.service_options(service)
    service = storage_provider_abbr_for_uri(service) if service.is_a?(URI)
    options[service]
  end

  def self.parse_service_options
    YAML::load(ERB.new(File.read(service_options_file_path)).result).with_indifferent_access
  end

  def self.service_options_file_path=(fp)
    @_file_path = fp
  end

  def self.service_options_file_path
    @_file_path ||= "#{root}/config/services.yml"
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

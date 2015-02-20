# encoding: utf-8

require 'socket'
require 'ohai'

module SystemInformation

  @semaphore = Mutex.new

  @ohai_system = nil

  def self.ohai_system
    @semaphore.synchronize {
      if @ohai_system == nil
        @ohai_system = Ohai::System.new
        @ohai_system.all_plugins
      end
    }
    @ohai_system
  end

  def self.ohai_public_ip_address
    public_ip = ohai_system.data[:cloud][:public_ipv4] rescue nil
    public_ip
  end

  def self.local_public_ip_address
    ip = Socket.ip_address_list.detect{|intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private?}
    ip.ip_address if ip
  end

  def self.public_ip_address
    if env == 'production'
      ohai_public_ip_address
    else
      local_public_ip_address
    end
  end

  def self.env
    @env ||= (defined?(Rails) && Rails.respond_to?(:env) && Rails.env) ||
    ENV['RAILS_ENV'] || ENV['APP_ENV'] ||
    'development'
  end
end

require 'ipaddr'
require 'net/ftp'

# N.B. look at Socket AddrInfo stdlib, might be a better way to do this
class IPAddr

  IP4_PRIVATE_RANGES = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("127.0.0.0/8")
  ]

  IP6_PRIVATE_RANGES = [
    IPAddr.new("fc00::/7"),
    IPAddr.new("::1")
  ]

  def private?
    ranges = self.ipv6? ? IP6_PRIVATE_RANGES : IP4_PRIVATE_RANGES
    ranges.each do |ipr|
      return true if ipr.include?(self)
    end
    return false
  end

  def public?
    !private?
  end
end

module Net
  class FTP

    # provide a masquerade_host to be able to override incorrect PASV response
    attr_accessor :local_host

    attr_accessor :remote_host

    # set to override host when ftp server returns a private/loopback IP on PASV
    attr_accessor :override_local

    # also use to do the samwe thing on

    def makepasv_with_override
      host, port = makepasv_without_override
      # puts "host: #{host.inspect}, sock remote ip: #{@sock.remote_address.ip_address}"
      if remote_host
        host = remote_host
      elsif override_local && IPAddr.new(host).private?
        host = @sock.remote_address.ip_address
      end
      # puts "makepasv host:#{host}, port:#{port}"
      return host, port
    end

    alias_method :makepasv_without_override, :makepasv
    alias_method :makepasv, :makepasv_with_override

    def makeport_with_override
      sock = TCPServer.open(@sock.addr[3], 0)
      port = sock.addr[1]
      host = local_host ? local_host : sock.addr[3]

      sendport(host, port)

      return sock
    end

    alias_method :makeport_without_override, :makeport
    alias_method :makeport, :makeport_with_override

  end
end

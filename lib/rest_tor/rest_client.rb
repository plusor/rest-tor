require 'socksify/http'
module RestClient
  class Request

    def net_http_object_with_socksify(hostname, port)
      p_uri = proxy_uri
      if p_uri && p_uri.scheme =~ /^socks5?$/i
        return Net::HTTP.SOCKSProxy(p_uri.hostname, p_uri.port).new(hostname, port)
      end

      net_http_object_without_socksify(hostname, port)
    end

    alias_method :net_http_object_without_socksify, :net_http_object
    alias_method :net_http_object, :net_http_object_with_socksify

  end
end

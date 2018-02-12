module Tor
  class Configuration
    def initialize
      @config = {
        count:  10,   # Init count
        port:   9000, # Listen port start with 9000
        dir:    Pathname.new('/tmp/tor'),  # 
        ipApi:  'http://ip.plusor.cn/',
        ipParser: ->(body) { body[/\d{,3}\.\d{,3}\.\d{,3}\.\d{,3}/] },
        command: -> (port) { "tor --RunAsDaemon 1 --CookieAuthentication 0 --HashedControlPassword \"\"  --ControlPort auto --PidFile #{Tor.dir(port)}/tor.pid --SocksPort #{port} --DataDirectory #{Tor.dir(port)}  --CircuitBuildTimeout 5 --KeepalivePeriod 60 --NewCircuitPeriod 15 --NumEntryGuards 8 --quiet" }
      }
    end

    def method_missing(method_id, *args, &block)
      if /(?<name>.*?)=$/ =~ method_id.to_s
        @config[:"#{name}"] = args.first
      elsif @config.key?(:"#{method_id}")
        @config[:"#{method_id}"]
      else
        super
      end
    end
  end
end

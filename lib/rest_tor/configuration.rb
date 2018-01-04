module Tor
  class Configuration
    def initialize
      @config = {
        count:  10,   # Init count
        port:   9000, # Listen port start with 9000
        dir:    Pathname.new('/tmp/tor')  # 
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

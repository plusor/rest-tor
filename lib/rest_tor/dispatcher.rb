module Tor
  module Dispatcher
    def self.modes
      @modes ||= {}
    end

    def self.register(name, &block)
      modes[name] = block
    end

    def self.take(mode: :default)
      Tor.lock("tor:pick", expires: 10) do
        port, tor = run(mode)
        if port.blank? || tor.blank?
          port, _ = Tor.store.max {|a,b | a[0] <=> b[0] } || Tor.config.port
          tor     = Tor.listen(port=port.next)
        end
        return [port, tor]
      end

      return []
    end

    def self.run(name)
      @modes[:"#{name}"].call
    end

    register :default do
      Tor.store.all.sort_by do |(port, tor)|
        tor.c_fail - tor.c_success
      end.detect { |(port, tor)| !tor.using? && tor.use!  }
    end

    register :order do
      Tor.store.all.sort_by do |(port, tor)|
        port
      end.detect { |(port, tor)| !tor.using? && tor.use!  }
    end
  end
end
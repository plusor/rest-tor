require 'rest_tor/strategy/restart'
require 'forwardable'

module Tor
  class Instance
    include Strategy::Restart
    extend Forwardable

    ATTRS = %i(ip port using counter)

    attr_accessor *ATTRS

    def_delegators :@counter, :success!, :fail!
    def_delegator :@counter, :success, :c_success
    def_delegator :@counter, :fail, :c_fail

    def initialize(port, ip: nil, using: nil, counter: nil)
      @port   = port
      @ip     = ip
      @using  = using
      @counter= Counter.new(self, counter || {})
    end

    def pid
      path = Tor::TOR_DIR.join("#{port}/tor.pid")
      if File.exists?(path)
        File.read(path).chomp.to_i
      end
    end

    def attributes
      { ip: @ip, port: @port, using: @using, counter: @counter.to_h }
    end

    ATTRS.each do |name|
      define_method :"#{name}=" do |value|
        apply do
          instance_variable_set("@#{name}", value)
        end
      end
    end

    def last?
      Tor.store.max_by {|(k, v)| k}.try(:first).to_s == port.to_s
    end

    def release!
      self.using = nil

      if Tor.locked?("#{port}:restart")
        logger.info "The tor(#{port}) already processing!"
      else
        if error=died?
          restart!("Died(#{error})")
        end
      end
      true
    end

    def restart!(message="")
      logger.info "#{message} Restart => #{ip}:#{port}"
      Tor.restart(port)
    end

    def use!
      self.using = Time.now
    end

    def using?
      @using.present?
    end

    def stop
      Tor.stop(port)
    end

    alias_method :destroy, :stop

    def apply(&block)
      Tor.lock("tor:#{port}:update", expires: 1.minutes) do
        if not Tor.store.has_key?(port)
          logger.info "Has been destroyed"
          return
        end
        if block_given?
          yield.tap do
            Tor.store[port] = attributes
          end
        else
          Tor.store[port] = attributes
        end
      end
    end

    def avaliable?
      begin
        pid && Process.getpgid( pid ) && true
      rescue Errno::ESRCH
        false
      end
    end
  end

  class Counter < BasicObject
    attr_accessor :success, :fail, :success_at, :fail_at, :errors
    def initialize(tor, success: 0, fail: 0, success_at: nil, fail_at: nil, errors: {})
      @tor        = tor
      @success    = success
      @fail       = fail
      @success_at = success_at
      @fail_at    = fail_at
      @errors     = errors.is_a?(::Hash) ? errors : {}
    end

    def inspect
      "#<Counter success: #{@success}, fail: #{@fail}, succss_at: #{@success_at}, fail_at:#{@fail_at}>"
    end

    def to_h
      { success: @success, fail: @fail, success_at: @success_at, fail_at: @fail_at, errors: @errors }
    end

    def success!
      @tor.apply do
        @success += 1
        @success_at = ::Time.now
      end
    end

    def fail!(e)
      if e.is_a?(::Exception)
        errors[e.class] ||= 0
        errors[e.class] += 1
      else
        erros[e] ||= 0
        erros[e] += 1
      end

      @tor.apply do
        @fail += 1
        @fail_at = ::Time.now
      end
    end
  end
end
require 'pathname'
module Tor extend self
  extend Lock
  class Error < StandardError; end
  class UnvaliablePort < Error; end
  class DiedPortError < Error; end
  class InvalidFormat < Error; end
  USER_AGENT          = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36'
  MOBILE_AGENT        = 'ANDROID_KFZ_COM_2.0.9_M6 Note_7.1.2'
  TOR_COUNT           = 10
  TOR_PORT_START_WITH = 9000
  TOR_DIR             = Pathname.new('/tmp/tor')

  def init
    lock("tor:init", expires: 1.minutes) do
      TOR_COUNT.times do |i|
        listen(TOR_PORT_START_WITH + i + 1)
      end
    end
  end

  def store
    @store ||= Redis::HashKey.new('tor', marshal: true).tap { |s| s.send(:extend, Builder) }
  end

  def hold_tor(mode: :default, &block)
    if tor=Thread.current[:tor]
      port = tor.port
    else
      port, tor = Dispatcher.take(mode: mode)
    end

    Thread.current[:tor] = tor

    if block_given?
      yield port, tor
    end
  ensure
    Thread.current[:tor] = nil
    tor && tor.release!
  end

  def request(options={}, &block)
    url     = options[:url]
    mode    = options[:mode] || :default
    raw     = options[:raw].nil? ? true : false
    method  = options[:method] || :get
    payload = options[:payload] || {}
    timeout = options[:timeout] || 10
    format  = options[:format] || (raw ? :html : :string)
    mobile  = options[:mobile]
    default_header = { 'User-Agent' => mobile ? MOBILE_AGENT : USER_AGENT }
    time, body = Time.now, nil

    hold_tor(mode: mode) do |port, tor|
      logger.info "Started #{method.to_s.upcase} #{url.inspect} (port:#{port} | mode:#{mode}"
      params = {
        method: method,
        url: url,
        payload: payload,
        proxy: "socks5://127.0.0.1:#{port}",
        timeout: timeout,
        headers: default_header.merge(options[:header] || {})
      }

      begin
        response = RestClient::Request.execute(params) do |res, req, headers|
           yield(res, req, headers ) if block_given?
           res
        end
        tor.success!
        body = response.body
        logger.info "Completed #{response.try(:code)} OK in #{(Time.now-time).round(1)}s (Size: #{Utils.number_to_human_size(body.bytesize)})"
      rescue Exception => e
        tor.fail!(e)
        logger.info "#{e.class}: #{e.message}, <Tor#(success: #{tor.counter.success}, fail: #{tor.counter.fail}, port: #{tor.port})>"
        raise e
      end
    end
    case format.to_s
      when "html"    then Nokogiri::HTML(Utils.encode_html(body))
      when "json"    then Utils.to_json(body)
      when "string"  then body
    else
      raise InvalidFormat, format.to_s
    end
  end

  def stop(port)
    logger.info "Stop tor port:#{port}"
    instance = store[port]
    if instance && instance.pid
      Process.kill("KILL", instance.pid)
    end
    FileUtils.rm_rf(TOR_DIR.join(port.to_s))
  rescue Exception
    
  ensure
    store.delete(port)
  end

  def listen(port)
    return if port.blank? || !port.to_s.match(/^\d+$/)

    logger.info "Open tor with port:#{port}"

    control_port = 6000 + port.to_i

    tor = 'tor --RunAsDaemon 1 --CookieAuthentication 0 --HashedControlPassword ""'
    tor+= " --ControlPort #{ control_port } --PidFile tor.pid --SocksPort #{port} --DataDirectory #{dir(port)}"
    tor+= " --CircuitBuildTimeout 5 --KeepalivePeriod 60 --NewCircuitPeriod 15 --NumEntryGuards 8"# make tor faster
    tor+= " --quiet" # unless Rails.env.production?
    system tor
    sleep 5
    if ip=test(port)
      store.insert(port, ip)
    else
      tor = Tor.store[port]
      raise DiedPortError if tor&.died?
      raise UnvaliablePort if !tor
    end
  rescue Error, RestClient::Exception => e
    stop(port)
    logger.info "#{e.class}:#{e.message}"
    retry
  end

  def restart(port)
    lock("tor:#{port}:restart", expires: 1.minutes) do
      stop(port)
      listen(port)
    end
  end

  def dir(port)
    TOR_DIR.join("#{port}").tap do |dir|
      FileUtils.mkpath(dir) if not Dir.exists?(dir)
    end
  end

  def test(port)
    logger.info  "Testing tor #{port}"

    url = 'http://ip.plusor.cn/'

    req = RestClient::Request.execute({method: :get, url: url, proxy: "socks5://127.0.0.1:#{port}"})
    req.body.chomp.tap do |body|
      logger.info "  IP: #{body} "
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SOCKSError, SOCKSError::TTLExpired, Errno::ECONNRESET => e
    logger.error "#{e.class}: #{e.message}"
    false
  end

  def clear
    Dir.glob(TOR_DIR.join("**/*.pid")).each do |path|
      begin
        Process.kill("KILL", File.read(path).chomp.to_i)
      rescue Errno::ESRCH
      end
    end
    FileUtils.rm_rf(TOR_DIR)
    true
  ensure
    store.clear
  end

  def count
    Dir.glob(TOR_DIR.join("*")).count
  end

  def unused
    store.select {|_, options| !options.using? }
  end

  module Builder
    def [](key)
      if value=super(key)
        Instance.new key, safe_value(value)
      end
    end

    def all
      super.reduce({}) { |h, (k, v)| h[k] = Tor::Instance.new(k, safe_value(v)); h }
    end

    def insert(port, ip)
      self[port] = { ip: ip }
      self[port]
    end

    private
    def safe_value(value)
      counter = value.try(:[], :counter) || {}
      value.slice(*[:ip, :using]).merge({
        counter: counter.slice(*[:success, :fail, :success_at, :fail_at, :errors])
      })
    rescue NoMethodError => e
      value
    end
  end
end
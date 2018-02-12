require 'pathname'
require 'rest_tor/lock'
module Tor extend self
  extend Lock
  class Error < StandardError; end
  class UnvaliablePort < Error; end
  class DiedPortError < Error; end
  class InvalidFormat < Error; end
  USER_AGENT          = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36'
  MOBILE_AGENT        = 'ANDROID_KFZ_COM_2.0.9_M6 Note_7.1.2'

  def init
    lock("tor:init", expires: 1.minutes) do
      threads = []
      config.count.times { |i| threads << Thread.new { listen(config.port + i + 1) }  }
      threads.map(&:join)
    end
  end

  def store
    @store ||= Redis::HashKey.new('tor', marshal: true).tap { |s| s.send(:extend, Builder) }
  end

  def hold_tor(mode: :default, rest: false, &block)
    return yield if rest
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
    mobile  = options[:mobile]
    proxy   = options[:proxy]
    proxy   = nil if proxy == true
    raw     = options[:raw].nil? ? true : false
    mode    = options[:mode]    || :default
    method  = options[:method]  || :get
    payload = options[:payload] || {}
    timeout = options[:timeout] || 10
    format  = options[:format]  || (raw ? :html : :string)
    headers = options[:headers] || options[:header] || {}
    default_header = { 'User-Agent' => mobile ? MOBILE_AGENT : USER_AGENT }
    time, body = Time.now, nil
    rest    = proxy != nil

    hold_tor(mode: mode, rest: rest) do |port, tor|
      Thread.current[:tor] = tor if tor.present?

      proxy  ||= "socks5://127.0.0.1:#{port}" if not rest

      logger.info "Started #{method.to_s.upcase} #{url.inspect} (proxy:#{proxy} | mode:#{mode})"

      params  = {
        method:   method,
        url:      url,
        payload:  payload,
        proxy:    proxy,
        timeout:  timeout,
        headers:  default_header.merge(headers)
      }

      begin
        response = RestClient::Request.execute(params) do |res, req, headers|
          if res.code == 302
            res.follow_redirection
          else
            yield(res, req, headers ) if block_given?
            res
          end
        end
        tor&.success!
        body = response.body
        logger.info "Completed #{response.try(:code)} OK in #{(Time.now-time).round(1)}s (size: #{Utils.number_to_human_size(body.bytesize)})"
      rescue Exception => e
        if tor
          tor.fail!(e)
          logger.info "#{e.class}: #{e.message}, <Tor#(success: #{tor.counter.success}, fail: #{tor.counter.fail}, port: #{tor.port})>"
        end
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
    FileUtils.rm_rf dir(port)
  rescue Exception
    
  ensure
    store.delete(port)
  end

  def listen(port)
    return if port.blank? || !port.to_s.match(/^\d+$/)

    logger.info "Open tor with port:#{port}"

    system config.command.call(port)

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
    config.dir.join("#{port}").tap do |dir|
      FileUtils.mkpath(dir) if not Dir.exists?(dir)
    end
  end

  def test(port)
    logger.info  "Testing tor #{port}"

    req = RestClient::Request.execute({method: :get, url: config.ipApi, proxy: "socks5://127.0.0.1:#{port}"})
    config.ipParser.call(req.body).tap do |ip|
      logger.info "  IP: #{ip} "
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SOCKSError, SOCKSError::TTLExpired, Errno::ECONNRESET => e
    logger.error "#{e.class}: #{e.message}"
    false
  end

  def clear
    Dir.glob(config.dir.join("**/*.pid")).each do |path|
      begin
        Process.kill("KILL", File.read(path).chomp.to_i)
      rescue Errno::ESRCH
      end
    end
    FileUtils.rm_rf(config.dir)
    true
  ensure
    store.clear
  end

  def count
    Dir.glob(config.dir.join("*")).count
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
      value.slice(*[:ip, :using, :created_at]).merge({
        counter: counter.slice(*[:success, :fail, :success_at, :fail_at, :errors])
      })
    rescue NoMethodError => e
      value
    end
  end
end
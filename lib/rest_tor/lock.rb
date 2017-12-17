module Tor
  module Lock
    def lock(key, expires: 10.minutes, timeout: 1.hour, &block)
      Redis::Lock.new("tor:lock:#{key}", expiration: expires, timeout: timeout).lock { yield }
    end

    def locked?(key)
      Redis.current.get("tor:lock:#{key}")
    end

    def unlock!(key)
      Redis.current.del("tor:lock:#{key}")
    end
  end
end
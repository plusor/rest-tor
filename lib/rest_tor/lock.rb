module Tor
  module Lock
    def lock(key, expires: 10*60, timeout: 1 * 60 * 0, &block)
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
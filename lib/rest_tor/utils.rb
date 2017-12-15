module Tor
  module Utils extend self
    def to_json(body)
      JSON.parse(body)
    rescue Exception => e
      $Logger.tag("ERROR") { "#{e.class}:#{e.message}" }
      {}
    end

    def number_to_human_size(num, options={})
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert num, options
    end
    
    def encode_html(body)
      if /<meta .*?content=".*?charset=(\w+)"/ =~ body.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
        encode = $1
        if /utf-8/i !~ encode
          begin
            body = body.dup.force_encoding(encode).encode("utf-8", invalid: :replace, under: :replace) 
          rescue Exception => e
            $Logger.tag("ERROR") { "#{e.class}:#{e.message}(Tor.request)" }
          end
        end
      end
      body
    end

    def with_lock(key)
      name = "utils:with_lock:#{key}"
      pid = Redis.current.get(name)
      begin
        raise LockedError if pid.blank? or Process.getpgid(pid.to_i)
      rescue Errno::ESRCH, LockedError
        yield if Redis.current.setnx(name, Process.pid)
      end
    ensure
      Redis.current.del(name)
    end
  end
end
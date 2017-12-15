module Tor
  module Strategy
    module Restart
      DEFAULT_EXCEPTION_COUNT = 50
      EXCEPTIONS = {
        ::Net::OpenTimeout    => 20,
        ::Errno::ECONNREFUSED => 50,
        ::RestClient::Exceptions::OpenTimeout => 20
      }

      def died?
        message = nil
        return message if counter.errors.any? do |k,v|
          if EXCEPTIONS.key?(k)
            message = "#{k} count >= #{EXCEPTIONS[k]}" if v.to_i >= (EXCEPTIONS[k] || DEFAULT_EXCEPTION_COUNT)
          else
            message = "#{k} count >= #{DEFAULT_EXCEPTION_COUNT}" if v.to_i >= DEFAULT_EXCEPTION_COUNT
          end
        end

        if c_success > 0 && c_fail > (c_success << 5)
          message = "fail > success << 5 & success > 0"
        elsif c_success == 0 and c_fail > 50
          message = "fail > 50 & success = 0"
        end
        message.presence
      end
    end
  end
end
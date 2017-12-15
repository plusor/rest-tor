require 'nokogiri'
require 'rest-client'
require 'redis-objects'
require 'active_support/all'
require 'logger'
Dir.glob(File.expand_path('../rest_tor/**/*.rb', __FILE__)).each { |file| require file }

module Tor
  def self.logger
    Logger.new(STDOUT).tap do |log|
      log.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%3N')}] [#{Process.pid}-#{Thread.current.object_id}] #{msg}\n"
      end
    end
  end
end

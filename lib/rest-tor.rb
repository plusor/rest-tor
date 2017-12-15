require 'nokogiri'
require 'rest-client'
require 'redis-objects'
require 'active_support/all'
require 'logger'
Dir.glob(File.expand_path('../rest_tor/**/*.rb', __FILE__)).each { |file| require file }

module Tor
  def self.logger
    Logger.new(STDOUT)
  end
end

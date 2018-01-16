require 'test_helper'

class TorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Tor::VERSION
  end
end

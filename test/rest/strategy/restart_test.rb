require 'test_helper'

class Tor::Strategy::RestartTest < Minitest::Test
  def test_died?
    Tor.clear
    tor = nil
    Tor.request(url: 'https://github.com') do
      tor = Thread.current[:tor]
      tor.apply { tor.counter.fail = 20 }
    end
    assert tor.created_at != Tor.store[tor.port]
  end
end

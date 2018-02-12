# Rest Tor

Tor for ruby.  Support for multiple processes.  Each request will take an tor instance.

Tor.request will  take an instance if has tor instanc, otherwise initialize an instance.

## What can it do

- Web Crawler

## Requirements

- Tor

  Mac os:  brew install tor

  Linux: apt-get install tor

## Installation


Add this line to your application's Gemfile:

```ruby
gem 'rest-tor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rest-tor

## Usage

#### SETUP

```ruby
# Default setup
Tor.setup do
  config.count      =   10,   # Init count
  config.port       =   9000, # Listen port start with 9000
  config.dir        =   Pathname.new('/tmp/tor'),  # 
  config.ipApi      =   'http://ip.plusor.cn/', # get tor ip
  config.ipParser   =   -> (body) { body[/\d{,3}\.\d{,3}\.\d{,3}\.\d{,3}/] },   # get tor ip
  config.command    =   -> (port) { "tor --RunAsDaemon 1 --CookieAuthentication 0 --HashedControlPassword \"\"  --ControlPort auto --PidFile #{Tor.dir(port)}/tor.pid --SocksPort #{port} --DataDirectory #{Tor.dir(port)}  --CircuitBuildTimeout 5 --KeepalivePeriod 60 --NewCircuitPeriod 15 --NumEntryGuards 8 --quiet" }
end
```

####  Tor.request Options
- `method` | Default get
- `url`. Request url
- `payload`. Request data
- `header` or `headers`. Default: `Tor::USER_AGENT`)
- `mobile`. Default is false. If true, use the Mobile-side User-Agent
- `proxy` Default use tor proxy. IF false, do not use proxy. You can specify proxy as `host:port`.
- `raw` Default true. The result is Nokogiri::HTML(req.body). If false, then req.body
- `format`. Default `html`. Avaliable formats:  `html`, `json`, `string`.
- `mode` Default is  `:default`.
- `timeout` Request timeout


```ruby
Tor.request(url: 'http://ip.plusor.cn/')
=> #<Nokogiri::HTML::Document:0x3fcd64ec6eb0 name="document" children=[#<Nokogiri::XML::DTD:0x3fcd64ec6af0 name="html">, #<Nokogiri::XML::Element:0x3fcd64ec67f8 name="html" children=[#<Nokogiri::XML::Element:0x3fcd64ec6618 name="body" children=[#<Nokogiri::XML::Element:0x3fcd64ec6438 name="p" children=[#<Nokogiri::XML::Text:0x3fcd64ec6258 "185.100.85.101\n">]>]>]>]> 

Tor.request(url: 'http://ip.plusor.cn/', raw: false)
"64.113.32.29\n" 

Tor.request(url: 'http://ip.plusor.cn/', mobile: true) # ..."User-Agent"=>"ANDROID_KFZ_COM_2.0.9_M6 Note_7.1.2"
Tor.request(url: 'http://ip.plusor.cn/') # ..."User-Agent"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko)

Tor.request(method: :post, url: '...', format: :json, mobile: true)
=> {'hello' => 'world'}

Tor.request(url: '...', timeout: 10)

Tor.request(url: '...', mode: :default)  # Priority to use the highest number of successes, default is :default
Tor.request(url: '...', mode: :order) # in order

     # Customize an mode
Tor::Dispatcher.register :custom do
Tor.store.all.sort_by do |(port, tor)|
  tor.c_success
end
end
Tor.request(url: '...', mode: :custom)

# show all instances
Tor.store.all
=> {"9001"=>#<Tor::Instance:0x007fb7798d2498 @port="9001", @ip="64.113.32.29", @using=nil, @counter=#<Counter success: 5, fail: 1, succss_at: 2017-12-15 19:52:44 +0800, fail_at:2017-12-15 19:52:26 +0800>>}
# Clear instances
Tor.clear
# Stop instance
Tor.stop(port)

# proxy default is true
Tor.request(url: 'http://ip.plusor.cn',raw: false, proxy: false)
[2017-12-16 16:19:34.545] [95646-70129455200740] Started GET "http://ip.plusor.cn" (port:rest-client | mode:default)
[2017-12-16 16:19:34.785] [95646-70129455200740] Completed 200 OK in 0.2s (Size: 15 Bytes)
=> "172.104.89.163\n"

# Initialize tors
Tor.init
I, [2017-12-15T20:40:36.189835 #60422]  INFO -- : Open tor with port:9001
I, [2017-12-15T20:40:41.242452 #60422]  INFO -- : Testing tor 9001
I, [2017-12-15T20:40:42.881857 #60422]  INFO -- :   IP: 163.172.67.180 
I, [2017-12-15T20:40:42.882737 #60422]  INFO -- : Open tor with port:9002
I, [2017-12-15T20:40:47.931555 #60422]  INFO -- : Testing tor 9002
I, [2017-12-15T20:41:18.924004 #60422]  INFO -- :   IP: 155.4.230.97 
I, [2017-12-15T20:41:18.925154 #60422]  INFO -- : Open tor with port:9003
I, [2017-12-15T20:41:23.971647 #60422]  INFO -- : Testing tor 9003
I, [2017-12-15T20:41:46.111952 #60422]  INFO -- :   IP: 46.17.97.112 
I, [2017-12-15T20:41:46.112896 #60422]  INFO -- : Open tor with port:9004
I, [2017-12-15T20:41:51.164009 #60422]  INFO -- : Testing tor 9004
I, [2017-12-15T20:42:20.096998 #60422]  INFO -- :   IP: 109.201.133.100 
I, [2017-12-15T20:42:20.097992 #60422]  INFO -- : Open tor with port:9005
I, [2017-12-15T20:42:25.148808 #60422]  INFO -- : Testing tor 9005
I, [2017-12-15T20:43:01.699053 #60422]  INFO -- :   IP: 62.210.129.246 
I, [2017-12-15T20:43:01.700151 #60422]  INFO -- : Open tor with port:9006
I, [2017-12-15T20:43:06.756239 #60422]  INFO -- : Testing tor 9006
I, [2017-12-15T20:43:39.118469 #60422]  INFO -- :   IP: 163.172.160.182 
I, [2017-12-15T20:43:39.119310 #60422]  INFO -- : Open tor with port:9007
I, [2017-12-15T20:43:44.194975 #60422]  INFO -- : Testing tor 9007
I, [2017-12-15T20:44:23.526274 #60422]  INFO -- :   IP: 89.144.12.14 
I, [2017-12-15T20:44:23.527287 #60422]  INFO -- : Open tor with port:9008
I, [2017-12-15T20:44:28.575018 #60422]  INFO -- : Testing tor 9008
I, [2017-12-15T20:44:51.746405 #60422]  INFO -- :   IP: 195.22.126.147 
I, [2017-12-15T20:44:51.747258 #60422]  INFO -- : Open tor with port:9009
I, [2017-12-15T20:44:56.793446 #60422]  INFO -- : Testing tor 9009
I, [2017-12-15T20:45:32.469774 #60422]  INFO -- :   IP: 62.210.129.246 
I, [2017-12-15T20:45:32.470560 #60422]  INFO -- : Open tor with port:9010
I, [2017-12-15T20:45:37.528114 #60422]  INFO -- : Testing tor 9010
I, [2017-12-15T20:46:37.533066 #60422]  INFO -- : Stop tor port:9010
I, [2017-12-15T20:46:37.533927 #60422]  INFO -- : RestClient::Exceptions::OpenTimeout:Timed out connecting to server
I, [2017-12-15T20:46:37.534015 #60422]  INFO -- : Open tor with port:9010
I, [2017-12-15T20:46:42.588824 #60422]  INFO -- : Testing tor 9010
I, [2017-12-15T20:47:02.179464 #60422]  INFO -- :   IP: 173.254.216.66
```

## TODO

- Test
- Optimization code
- Configurable http client
 - Add chrome headless
- Configurable restart strategy

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/plusor/rest-tor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


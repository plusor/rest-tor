# Rest::Tor

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/rest/tor`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

      Tor.request(url: 'http://ip.plusor.cn/')
       => #<Nokogiri::HTML::Document:0x3fcd64ec6eb0 name="document" children=[#<Nokogiri::XML::DTD:0x3fcd64ec6af0 name="html">, #<Nokogiri::XML::Element:0x3fcd64ec67f8 name="html" children=[#<Nokogiri::XML::Element:0x3fcd64ec6618 name="body" children=[#<Nokogiri::XML::Element:0x3fcd64ec6438 name="p" children=[#<Nokogiri::XML::Text:0x3fcd64ec6258 "185.100.85.101\n">]>]>]>]> 

      Tor.request(url: 'http://ip.plusor.cn/', raw: false)
      "64.113.32.29\n" 

      Tor.request(url: 'http://ip.plusor.cn/', mobile: true) # RestClient.get "http://ip.plusor.cn/", "", "Accept"=>"*/*", "Accept-Encoding"=>"gzip, deflate", "Content-Length"=>"0", "Content-Type"=>"application/x-www-form-urlencoded", "User-Agent"=>"ANDROID_KFZ_COM_2.0.9_M6 Note_7.1.2"
      Tor.request(url: 'http://ip.plusor.cn/') # RestClient.get "http://ip.plusor.cn/", "", "Accept"=>"*/*", "Accept-Encoding"=>"gzip, deflate", "Content-Length"=>"0", "Content-Type"=>"application/x-www-form-urlencoded", "User-Agent"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36"

      Tor.request(method: :post, url: '...', format: :json, mobile: true)
      => {'hello' => 'world'}

      Tor.request(url: '...', timeout: 10)

      Tor.request(url: '...', mode: :default)  # Priority to use the highest number of successes, default is :default
      Tor.request(url: '...', mode: :order) # in order


## TODO

- Test
- Optimization code
- Add config
- Configurable restart strategy
- Configurable dispatcher

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rest-tor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


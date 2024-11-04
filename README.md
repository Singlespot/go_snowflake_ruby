# GoSnowflakeRuby

This gem is a Ruby wrapper for the Snowflake Go Driver.
This gem is still in early development and is not ready for production use.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add go_snowflake_ruby

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install go_snowflake_ruby

## Usage

Init the driver with the connection string:

```ruby
require 'go_snowflake_ruby'

driver = GoSnowflakeRuby::Driver.new(connection_string: 'user:password@snowflake_client/database?wharhouse=...&role=...&schema')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/go_snowflake_ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/go_snowflake_ruby/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GoSnowflakeRuby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/go_snowflake_ruby/blob/master/CODE_OF_CONDUCT.md).

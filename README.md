# EtrieveContentApi

Ruby wrapper for accessing the Etrieve Content API. Document metadata and content retrieval is currently supported. Document writes may be supported in a future version.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'etrieve_content_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install etrieve_content_api


## Configuration

Configuration can be passed as a hash.

```ruby
{
  auth_url: 'https://example.com/auth', # default: ''
  base_url: 'https://example.com/api', # default: ''
  password: password, # default: ''
  username: username, # default: ''
  timeout: 1, # default: 30 seconds
  verify_ssl: false # default: true
}
```

Configuration can be read from a YAML file by passing the file path. The file should contain a hash structure and ERB content is evaluated:
```yaml
  ---
  auth_url: 'https://example.com/auth',
  base_url: 'https://example.com/api',
  password: password,
  username: username,
  timeout: 1,
  verify_ssl: false
```

## Usage
### Basic Request

See [Handler](lib/etrieve_content_api/handler.rb) class for prebuilt requests for things like document metadata and content.

```ruby
require 'etrieve_content_api'
handler = EtrieveContentApi::Handler.new(config_hash_or_path_to_config_yaml)
handler.document_metadata({:q => 'Sue'})
```

### Using EtrieveContentApi::Connection
Connection#execute can be used to wrap a group of calls with a single authentication request.
```ruby
conn = EtrieveContentApi::Connection.new(config_hash_or_path_to_config_yaml)
conn.execute() {
  @custom1 = conn.get_custom_connection([conn.base_url, 'custom_path1'].join('/'), conn.headers)
  @custom2 = conn.get_custom_connection([conn.base_url, 'custom_path2'].join('/'), conn.headers)
}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/reed_college/etrieve_content_api.

## License

The gem is available as open source under the terms of the [ BSD-3-Clause License](https://opensource.org/licenses/BSD-3-Clause).

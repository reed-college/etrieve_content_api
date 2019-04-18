require 'rubygems'
gem 'minitest'

require 'minitest/autorun'
require 'minitest/pride'

require 'webmock/minitest'

require File.expand_path('../lib/etrieve_content_api.rb', __dir__)

WebMock.disable_net_connect!(allow_localhost: true)

# stubs requests for authentication
def stub_connection_round_trip(connection)
  @auth_token = connection.auth_token
  @auth_response_body = File.read(
    File.join(
      __dir__, 'etrieve_content_api', 'test_stubs', 'auth_response_body.json'
    )
  )
  @stubbed_login = stub_request(
    :post, connection.auth_url
  ).with(
    body: 'grant_type=client_credentials&scope=openid',
    headers: {
      authorization: "Basic #{@auth_token}",
      accept: 'application/json'
    }
  ).to_return(
    status: 200,
    body: @auth_response_body
  )
end

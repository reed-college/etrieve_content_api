require_relative '../test_helper'

def setup_configured_connection_with_hash
  @auth_url = 'http://auth.example.com'
  @base_url = 'http://base.example.com'
  @pw = 'test_banana'
  @username = 'test_monkey'
  @timeout = 360
  @verify_ssl = false
  @conn = EtrieveContentApi::Connection.new(
    auth_url: @auth_url,
    base_url: @base_url,
    password: @pw,
    username: @username,
    timeout: @timeout,
    verify_ssl: @verify_ssl
  )
end

def setup_configured_connection_with_yaml
  @conn = EtrieveContentApi::Connection.new(
    File.join(
      __dir__, 'test_stubs', 'etrieve_config.yml'
    )
  )
end

# stubs failed request for authentication
def stub_connection_failed_auth(connection)
  @auth_token = connection.auth_token
  @auth_response_body = File.read(
    File.join(
      __dir__, 'test_stubs', 'auth_response_body.json'
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
    status: 400,
    body: '{"error": "Something bad"}'
  )
end

describe EtrieveContentApi::Connection do
  %i[
    auth_url
    base_url
    connection
    headers
    timeout
    username
    verify_ssl
  ].each do |attr|
    it "should respond to #{attr}" do
      conn = EtrieveContentApi::Connection.new({})
      conn.must_respond_to attr
    end
  end

  describe 'initialize' do
    describe 'with no config' do
      it 'should raise config error' do
        err = -> { EtrieveContentApi::Connection.new(nil) }.must_raise(
          EtrieveContentApi::ConnectionConfigurationError
        )
        err.to_s.must_match(/invalid configuration/i)
      end
    end

    describe 'defaults initialization behavior' do
      before do
        @conn = EtrieveContentApi::Connection.new({})
      end

      it 'should have nil access_token' do
        @conn.instance_variable_get(:@access_token).must_be_nil
      end

      it 'should have string auth_url instance var' do
        @conn.instance_variable_get(:@auth_url).must_equal ''
      end

      it 'should have string base_url instance var' do
        @conn.instance_variable_get(:@base_url).must_equal ''
      end

      it 'should have nil connection instance var' do
        @conn.instance_variable_get(:@connection).must_be_nil
      end

      it 'should have empty hash headers' do
        @conn.instance_variable_get(:@headers).must_be_kind_of Hash
        @conn.instance_variable_get(:@headers).must_be :empty?
      end

      it 'should have string password instance var' do
        @conn.instance_variable_get(:@password).must_equal ''
      end

      it 'should set timeout instance var to 30' do
        @conn.instance_variable_get(:@timeout).must_equal 30
      end

      it 'should have string username instance var' do
        @conn.instance_variable_get(:@username).must_equal ''
      end

      it 'should have true verify_ssl instance var' do
        @conn.instance_variable_get(:@verify_ssl).must_equal true
      end
    end

    describe 'set config for new instances' do
      describe 'with hash config' do
        before do
          setup_configured_connection_with_hash
        end

        it 'should set auth_url' do
          @conn.auth_url.must_equal @auth_url
        end

        it 'should set base_url' do
          @conn.base_url.must_equal @base_url
        end

        it 'should set password' do
          @conn.instance_variable_get(:@password).must_equal @pw
        end

        it 'should set username' do
          @conn.username.must_equal @username
        end

        it 'should set timeout' do
          @conn.timeout.must_equal @timeout
        end

        it 'should set verify_ssl' do
          @conn.verify_ssl.must_equal @verify_ssl
        end
      end

      describe 'with yaml config' do
        before do
          setup_configured_connection_with_yaml
        end

        it 'should set auth_url' do
          @conn.auth_url.must_equal(
            'https://apiauth.example.com/idsrv/connect/token?'
          )
        end

        it 'should set base_url' do
          @conn.base_url.must_equal 'http://apibase.example.com'
        end

        it 'should set password' do
          @conn.instance_variable_get(:@password).must_equal 'funky_banana'
        end

        it 'should set username' do
          @conn.username.must_equal 'test_monkey'
        end

        it 'should set timeout' do
          @conn.timeout.must_equal 6
        end

        it 'should set verify_ssl' do
          @conn.verify_ssl.must_equal false
        end

        describe 'with erb' do
          it 'should interpret erb' do
            conn = EtrieveContentApi::Connection.new(
              File.join(
                __dir__, 'test_stubs', 'etrieve_config_erb.yml'
              )
            )
            conn.timeout.must_equal 6
          end
        end

        describe 'with missing config file' do
          it 'should raise config error' do
            err = -> { EtrieveContentApi::Connection.new('fakefile.yml') }.must_raise(
              EtrieveContentApi::ConnectionConfigurationError
            )
            err.to_s.must_match(/not found/i)
          end
        end

        describe 'with invalid config file' do
          it 'should raise config error' do
            err = lambda {
              EtrieveContentApi::Connection.new(
                File.join(
                  __dir__, 'test_stubs', 'etrieve_config_bad.yml'
                )
              )
            }.must_raise(
              EtrieveContentApi::ConnectionConfigurationError
            )
            err.to_s.must_match(/invalid syntax/i)
          end
        end
      end
    end
  end

  describe 'auth_token' do
    describe 'class meth' do
      it 'should generate string' do
        t = EtrieveContentApi::Connection.auth_token('blah', 'blech')
        t.must_be_kind_of String
        t.must_equal 'YmxhaDpibGVjaA=='
      end
    end

    describe 'instance meth' do
      it 'should call class method' do
        setup_configured_connection_with_hash
        EtrieveContentApi::Connection.stub(
          :auth_token,
          'foobarbaz',
          [@conn.username, @conn.instance_variable_get(:@password)]
        ) do
          @conn.auth_token.must_equal 'foobarbaz'
        end
      end
    end
  end

  describe 'connect' do
    describe 'success' do
      before do
        setup_configured_connection_with_hash
        stub_connection_round_trip(@conn)
        @conn.connect
      end

      it 'should request login url' do
        assert_requested @stubbed_login
      end

      it 'should assign instance var access_token' do
        @conn.instance_variable_get(:@access_token).must_equal 'someToken'
      end

      it 'should assign connection' do
        @conn.instance_variable_get(:@connection).must_be_kind_of Hash
        @conn.instance_variable_get(:@connection).must_equal JSON.parse(
          @auth_response_body
        )
      end
    end

    describe 'failed' do
      before do
        setup_configured_connection_with_hash
        stub_connection_failed_auth(@conn)
        @conn.connect
      end

      it 'should set connection to false' do
        @conn.instance_variable_get(:@connection).must_equal false
      end

      it 'should set access_token to nil' do
        @conn.instance_variable_get(:@access_token).must_be_nil
      end
    end
  end

  describe 'get' do
    before do
      setup_configured_connection_with_hash
      stub_connection_round_trip(@conn)
      @stubbed_get = stub_request(
        :get,
        [@base_url, 'go'].join('/')
      ).to_return(
        status: 200,
        body: 'some text'
      )
    end

    it 'should open connection' do
      @conn.get('go')
      assert_requested @stubbed_login
    end

    it 'should get input path at base url' do
      @conn.get('go')
      assert_requested @stubbed_get
    end
  end

  describe 'post' do
    before do
      setup_configured_connection_with_hash
      stub_connection_round_trip(@conn)
      @post_params = { 'a' => 'b' }
      @stubbed_post = stub_request(
        :post,
        [@base_url, 'go'].join('/')
      ).with(
        body: @post_params
      ).to_return(
        status: 200
      )
    end

    it 'should open connection' do
      @conn.post('go', payload: @post_params)
      assert_requested @stubbed_login
    end

    it 'should post to path at base url' do
      @conn.post('go', payload: @post_params)
      assert_requested @stubbed_post
    end
  end

  describe 'execute' do
    before do
      setup_configured_connection_with_hash
      stub_connection_round_trip(@conn)
    end

    it 'should connect connection' do
      @conn.execute { 'something to do' }
      assert_requested @stubbed_login
    end

    it 'should yield the block' do
      result = @conn.execute { 'something to do' }
      result.must_equal 'something to do'
    end
  end

  describe 'get_custom_connection' do
    before do
      setup_configured_connection_with_hash
      stub_connection_round_trip(@conn)
      @stubbed_get = stub_request(
        :get,
        [@base_url, 'go'].join('/')
      ).to_return(
        status: 200
      )
    end

    it 'should not open connection' do
      @conn.get_custom_connection('go')
      assert_not_requested @stubbed_login
    end

    it 'should get input path at base url' do
      @conn.get_custom_connection('go')
      assert_requested @stubbed_get
    end

    describe 'with auth failure' do
      before do
        @stubbed_get = stub_request(
          :get,
          [@base_url, 'go'].join('/')
        ).to_return(
          status: 401
        )
      end

      it 'should raise AuthenticationError' do
        -> { @conn.get_custom_connection('go') }.must_raise(
          EtrieveContentApi::AuthenticationError
        )
      end
    end

    # make sure unhandled error bubbles up
    describe 'for bad request' do
      before do
        @stubbed_get = stub_request(
          :get,
          [@base_url, 'go'].join('/')
        ).to_return(
          status: 400
        )
      end

      it 'should raise bad request error' do
        -> { @conn.get_custom_connection('go') }.must_raise(
          RestClient::BadRequest
        )
      end
    end
  end

  describe 'post_custom_connection' do
    before do
      setup_configured_connection_with_hash
      stub_connection_round_trip(@conn)
      @post_params = { 'a' => 'b' }
      @stubbed_post = stub_request(
        :post,
        [@base_url, 'go'].join('/')
      ).with(
        body: @post_params
      ).to_return(
        status: 200
      )
    end

    it 'should not open connection' do
      @conn.post_custom_connection('go', payload: @post_params)
      assert_not_requested @stubbed_login
    end

    it 'should post to input path at base url' do
      @conn.post_custom_connection('go', payload: @post_params)
      assert_requested @stubbed_post
    end

    describe 'with auth failure' do
      before do
        @post_params = { 'a' => 'b' }
        @stubbed_post = stub_request(
          :post,
          [@base_url, 'go'].join('/')
        ).with(
          body: @post_params
        ).to_return(
          status: 401
        )
      end

      it 'should raise AuthenticationError' do
        -> { @conn.post_custom_connection('go', payload: @post_params) }.must_raise(
          EtrieveContentApi::AuthenticationError
        )
      end
    end

    # make sure unhandled error bubbles up
    describe 'for bad request' do
      before do
        @post_params = { 'a' => 'b' }
        @stubbed_post = stub_request(
          :post,
          [@base_url, 'go'].join('/')
        ).with(
          body: @post_params
        ).to_return(
          status: 400
        )
      end

      it 'should raise bad request error' do
        -> { @conn.post_custom_connection('go', payload: @post_params) }.must_raise(
          RestClient::BadRequest
        )
      end
    end
  end
end

module EtrieveContentApi
  # Auth wrapper for and actual rest client calls to Etrieve Content API
  class Connection
    attr_reader :auth_url
    attr_reader :base_url
    attr_reader :connection
    attr_reader :headers
    attr_reader :timeout
    attr_reader :expires_at
    attr_reader :username
    attr_reader :verify_ssl

    CONFIG_KEYS = %i[
      auth_url
      base_url
      password
      timeout
      username
      verify_ssl
    ].freeze

    def initialize(config)
      if config.is_a?(String)
        configure_with(config)
      elsif config.is_a?(Hash)
        configure(config)
      else
        raise ConnectionConfigurationError,
              'Invalid configuration options supplied.'
      end
    end

    def self.auth_token(user, password)
      Base64.strict_encode64 [user, password].join(':')
    end

    def auth_token
      @auth_token ||= self.class.auth_token(username, @password)
    end

    def connect
      return @connection if @connection && active?
      begin
        resp = post_custom_connection(
          auth_url,
          payload: 'grant_type=client_credentials&scope=openid',
          headers: {
            authorization: "Basic #{auth_token}",
            accept: :json
          }
        )
        results = JSON.parse(resp)
      rescue RestClient::ExceptionWithResponse => err
        results = err.respond_to?(:response) ? JSON.parse(err.response) : err
      rescue
        results = { error: $!.message }
      end
      @access_token = results['access_token']
      if @access_token
        @headers = { authorization: "Bearer #{@access_token}" }
        @connection = results
        @expires_at = Time.now + results['expires_in'].to_i
      else
        reset!
      end
      results
    end

    def connect!
      reset!
      connect
    end

    def active?
      return false unless @expires_at.is_a?(Time)
      return false if @expires_at < Time.now - 5
      true
    end

    def reset!
      configure(@config)
    end

    def get(path, headers: {}, &block)
      execute(headers: headers) do
        get_custom_connection path, headers: @headers, &block
      end
    end

    def post(path, payload: nil, headers: {}, &block)
      execute(headers: headers) do
        post_custom_connection path, payload: payload, headers: @headers, &block
      end
    end

    # TODO: pass headers differently
    def execute(headers: {}, &block)
      connect
      return false unless @connection
      hold_headers = @headers
      @headers = merge_headers(headers)
      out = yield(block)
      @headers = hold_headers
      out
    end

    # Use this inside an execute block to make mulitiple calls in the same
    # request
    def get_custom_connection(path = '', headers: {}, &block)
      block ||= default_response_handler
      url = path =~ /\Ahttp/ ? path : [@base_url, path].join('/')
      rest_client_wrapper :get, url, headers: headers, &block
    end

    # Use this inside an execute block to make mulitiple calls in the same
    # request
    def post_custom_connection(path, payload: nil, headers: {}, &block)
      path ||= ''
      block ||= default_response_handler
      url = path =~ /\Ahttp/ ? path : [@base_url, path].join('/')
      RestClient::Request.execute(
        method: :post,
        url: url,
        payload: payload,
        headers: headers,
        verify_ssl: verify_ssl,
        timeout: timeout,
        &block
      )
    end

    private

    def rest_client_wrapper(method, url, headers: {}, &block)
      RestClient::Request.execute(
        method: method,
        url: url,
        headers: headers,
        verify_ssl: verify_ssl,
        timeout: timeout,
        &block
      )
    end

    # Configure using hash
    def configure(opts = {})
      @config = clean_config_hash(opts)

      @access_token = nil
      @auth_url = @config[:auth_url] || ''
      @base_url = @config[:base_url] || ''
      @connection = nil
      @headers = {}
      @request_headers = {}
      @password = @config[:password] || ''
      @timeout = @config[:timeout] || 30
      @username = @config[:username] || ''
      @verify_ssl = @config[:verify_ssl] != false
      @expires_at = nil
    end

    # Configure with yaml
    def configure_with(path_to_yaml_file)
      unless path_to_yaml_file.is_a?(String)
        raise ConnectionConfigurationError,
              'Invalid request. #configure_with requires string'
      end
      begin
        config = YAML.safe_load(
          ERB.new(IO.read(path_to_yaml_file)).result,
          symbolize_names: true
        )
      rescue Errno::ENOENT
        raise ConnectionConfigurationError,
              'YAML configuration file was not found.'
      rescue Psych::SyntaxError
        raise ConnectionConfigurationError,
              'YAML configuration file contains invalid syntax.'
      end
      configure(config)
    end

    def clean_config_hash(config)
      config = config.inject({}) { |h, (k, v)| h[k.to_sym] = v; h }
      CONFIG_KEYS.inject({}) { |h, k| h[k] = config[k]; h }
    end

    def merge_headers(headers = {})
      headers = @headers.merge(headers)
      headers[:auth_token] = @auth_token
      headers
    end

    def default_response_handler
      @default_response_handler ||= lambda do |response, _request, _result, &block|
        case response.code
        when 200
          return response
        when 401
          raise AuthenticationError
        else
          # Some other error. Let it bubble up.
          response.return!(&block)
        end
      end
    end
  end
end

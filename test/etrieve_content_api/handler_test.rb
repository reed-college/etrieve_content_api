require_relative '../test_helper'

def setup_configured_handler_with_hash
  @auth_url = 'http://auth.example.com'
  @base_url = 'http://base.example.com'
  @pw = 'test_banana'
  @username = 'test_monkey'
  @timeout = 360
  @verify_ssl = false
  @handler = EtrieveContentApi::Handler.new(
    auth_url: @auth_url,
    base_url: @base_url,
    password: @pw,
    username: @username,
    timeout: @timeout,
    verify_ssl: @verify_ssl
  )
end

describe EtrieveContentApi::Handler do
  %i[
    connection
  ].each do |attr|
    it "should respond to #{attr}" do
      conn = EtrieveContentApi::Handler.new({})
      conn.must_respond_to attr
    end
  end

  %i[
    API_PATH
    DOCUMENTS_PATH
  ].each do |const|
    it "should have string const #{const}" do
      EtrieveContentApi::Handler.const_get(const).must_be_kind_of String
    end
  end

  %i[
    DOCUMENT_METADATA_PARAMS
    PAGE_CONTENT_PARAMS
    DOCUMENT_CONTENT_PARAMS
  ].each do |const|
    it "should have array of symbols const #{const}" do
      EtrieveContentApi::Handler.const_get(const).must_be_kind_of Array
      EtrieveContentApi::Handler.const_get(const).each do |c|
        c.must_be_kind_of Symbol
      end
    end
  end

  describe 'initialize' do
    before do
      setup_configured_handler_with_hash
    end

    it 'should set connection' do
      @handler.connection.must_be_kind_of(
        EtrieveContentApi::Connection
      )
    end

    it 'should set config' do
      @handler.instance_variable_get(:@config).wont_be_nil
    end
  end

  describe 'with stubbed connections' do
    before do
      setup_configured_handler_with_hash
      stub_connection_round_trip(@handler.connection)
    end

    describe 'document' do
      it 'should get document document metadata path' do
        stubbed_request = stub_request(
          :get,
          [@base_url, EtrieveContentApi::Handler::DOCUMENTS_PATH].join('/')
        )
        @handler.document_metadata
        assert_requested stubbed_request
      end

      it 'should be hash' do
        stub_request(
          :get,
          [@base_url, EtrieveContentApi::Handler::DOCUMENTS_PATH].join('/')
        )
        @handler.document_metadata.must_be_kind_of Array
      end

      it 'should restrict query to DOCUMENT_METADATA_PARAMS' do
        stubbed_request = stub_request(
          :get,
          [@base_url, EtrieveContentApi::Handler::DOCUMENTS_PATH].join('/')
        ).with(
          query: {
            'q' =>  'Joe',
            'areaCode' => 'REG',
            'documentTypeCode' => 'Transcript',
            'fieldCode' => 'pidm',
            'fieldValue' => '1111',
            'limit' => '25',
            'offset' => '25',
            'fields' => 'id,name'
          }
        )
        @handler.document_metadata(
          query: {
            q: 'Joe',
            area_code: 'REG',
            document_type_code: 'Transcript',
            field_code: 'pidm',
            field_value: 1111,
            limit: 25,
            offset: 25,
            fields: 'id,name',
            bogus_thing: true
          }
        )
        assert_requested stubbed_request
      end
    end

    describe 'document_content' do
      describe 'with stubbed request' do
        before do
          @doc_id = 100
          @stubbed_request = stub_request(
            :get,
            [
              @base_url,
              EtrieveContentApi::Handler::DOCUMENTS_PATH, @doc_id, 'contents'
            ].join('/')
          )
        end

        it 'should get document content path' do
          @handler.document_content(@doc_id)
          assert_requested @stubbed_request
        end

        it 'should be RestClient::Response' do
          @handler.document_content(@doc_id).must_be_kind_of RestClient::Response
        end
      end

      it 'should restrict query to DOCUMENT_CONTENT_PARAMS' do
        doc_id = 100
        stubbed_request = stub_request(
          :get,
          [
            @base_url,
            EtrieveContentApi::Handler::DOCUMENTS_PATH, doc_id, 'contents'
          ].join('/')
        ).with(
          query: {
            'includeAnnotations' => 'false'
          }
        )
        @handler.document_content(
          doc_id,
          query: {
            include_annotations: false,
            bogus_thing: true
          }
        )
        assert_requested stubbed_request
      end
    end

    describe 'page_content' do
      describe 'with stubbed request' do
        before do
          @doc_id = 100
          @page = 2
          @stubbed_request = stub_request(
            :get,
            [
              @base_url,
              EtrieveContentApi::Handler::DOCUMENTS_PATH, @doc_id, 'contents', @page
            ].join('/')
          )
        end

        it 'should get page content path' do
          @handler.page_content(@doc_id, page: @page)
          assert_requested @stubbed_request
        end

        it 'should be RestClient::Response' do
          @handler.page_content(@doc_id, page: @page).must_be_kind_of(
            RestClient::Response
          )
        end
      end

      it 'should default to page 1' do
        doc_id = 100
        stubbed_request = stub_request(
          :get,
          [
            @base_url,
            EtrieveContentApi::Handler::DOCUMENTS_PATH, doc_id, 'contents', 1
          ].join('/')
        )
        @handler.page_content(doc_id)
        assert_requested stubbed_request
      end

      it 'should restrict query to PAGE_CONTENT_PARAMS' do
        doc_id = 100
        stubbed_request = stub_request(
          :get,
          [
            @base_url,
            EtrieveContentApi::Handler::DOCUMENTS_PATH, doc_id, 'contents', 1
          ].join('/')
        ).with(
          query: {
            'dpi' =>  '1200',
            'height' => '120',
            'includeAnnotations' => 'false',
            'width' => '180'
          }
        )
        @handler.page_content(
          doc_id,
          page: 1,
          query: {
            dpi: 1200,
            height: 120,
            include_annotations: false,
            width: 180,
            bogus_thing: true
          }
        )
        assert_requested stubbed_request
      end
    end

    describe 'get' do
      describe 'valid request' do
        before do
          @path = 'go/here'
          @stubbed_request = stub_request(
            :get,
            [@base_url, @path].join('/')
          ).to_return(
            status: 200,
            body: '{"thing": "Something interesting"}'
          )
        end

        it 'should request path' do
          @handler.get(@path)
          assert_requested @stubbed_request
        end

        it 'should return response object' do
          @handler.get(@path).must_be_kind_of RestClient::Response
        end
      end
    end

    describe 'get_json' do
      describe 'valid request' do
        before do
          @path = 'go/here'
          @stubbed_request = stub_request(
            :get,
            [@base_url, @path].join('/')
          ).to_return(
            status: 200,
            body: '{"thing": "Something interesting"}'
          )
        end

        it 'should request path' do
          @handler.get_json(@path)
          assert_requested @stubbed_request
        end

        it 'should return response object' do
          @handler.get_json(@path).must_be_kind_of Array
        end
      end

      it 'should return empty hashes for invalid json' do
        path = 'go/here'
        stub_request(
          :get,
          [@base_url, path].join('/')
        ).to_return(
          status: 200,
          body: 'Not JSON'
        )
        output = @handler.get_json(path)
        output.must_be_kind_of Array
        output.must_equal [{}, {}]
      end
    end
  end
end

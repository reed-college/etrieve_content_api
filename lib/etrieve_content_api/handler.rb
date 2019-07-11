module EtrieveContentApi
  class Handler
    API_PATH = 'api'.freeze
    DOCUMENTS_PATH = [API_PATH, 'documents'].join('/').freeze

    DOCUMENT_METADATA_PARAMS = %i[
      area_code
      document_type_code
      field_code
      field_value
      fields
      limit
      offset
      q
    ].freeze

    PAGE_CONTENT_PARAMS = %i[dpi height width include_annotations].freeze

    DOCUMENT_CONTENT_PARAMS = %i[include_annotations].freeze

    attr_reader :connection

    def initialize(connection_config)
      @config = connection_config
      @connection = Connection.new(@config)
    end

    # Get information for one or more documents
    # query:
    #   q: simple search
    #   area_code: document area
    #   document_type_code: document type
    #   field_code: field name for exact match of value in field_value
    #   field_value: field value for field_code
    #   limit: number of items to return
    #   offset: number of items to skip
    #   fields: comma-delimited list of fields to include
    def document_metadata(query: {}, headers: {}, &block)
      query_s = encoded_query(
        query: query,
        keys_allowed: DOCUMENT_METADATA_PARAMS
      )
      get_json DOCUMENTS_PATH, query: query_s, headers: headers, &block
    end

    # Calls #document_metadata in a loop retrieving per_request number of
    # documents until all matching docs are retrieved or loop_max is reached
    def all_document_metadata(
      query: {}, headers: {}, per_request: 25, loop_max: 10, &block
    )
      query[:limit] = per_request
      out = []
      loop_max.times do
        docs, resp_headers = document_metadata(query: query, headers: headers, &block)
        docs.empty? ? break : out << docs
        break if resp_headers[:x_hasmore] == 'False'
        query[:offset] = (query[:offset] || 0) + per_request
      end
      out.flatten
    end

    # Get content of a document
    # query:
    #   include_annotations: include all annotations? true/false
    def document_content(document_id, query: {}, headers: {}, &block)
      path = [DOCUMENTS_PATH, document_id, 'contents'].join('/')
      query_s = encoded_query(
        query: query,
        keys_allowed: DOCUMENT_CONTENT_PARAMS
      )
      get path, query: query_s, headers: headers, &block
    end

    # Get an image of a specific page of a document
    # query:
    #   height: max height
    #   width: max width
    #   dpi: dots per inch
    #   include_annotations: include all annotations? true/false
    def page_content(document_id, page: 1, query: {}, headers: {}, &block)
      path = [DOCUMENTS_PATH, document_id, 'contents', page].join('/')
      query_s = encoded_query(
        query: query,
        keys_allowed: PAGE_CONTENT_PARAMS
      )
      get path, query: query_s, headers: headers, &block
    end

    # Format a request and pass it on to the connection's get method
    def get(path = '', query: '', headers: {}, &block)
      query = query.empty? ? nil : query
      path = [path, query].compact.join('?')
      connection.get path, headers: headers, &block
    end

    # Process content from #get and parse JSON from body.
    def get_json(path = '', query: '', headers: {}, &block)
      r = get path, query: query, headers: headers, &block
      return { message: r } unless r.respond_to?(:body)

      json = begin
        JSON.parse(r.body)
      rescue JSON::ParserError
        {}
      end

      [json, r.headers]
    end

    private

    def encoded_query(query: {}, keys_allowed: :all)
      filtered_params = slice_hash(
        query, keys_allowed
      ).select do |_k, v|
        !v.nil? && !v.to_s.empty?
      end
      renamed_params = filtered_params.inject({}) do |h, (k, v)|
        h[camelize(k)] = v
        h
      end
      URI.encode_www_form(renamed_params)
    end

    # Keep only specified keys
    def slice_hash(orig_hash, keys_allowed = :all)
      return orig_hash if keys_allowed == :all
      orig_hash.select { |k, _v| keys_allowed.include?(k) }
    end

    def camelize(str)
      str.to_s.split('_').map(&:capitalize).join.sub(/^[A-Z]/, &:downcase)
    end
  end
end

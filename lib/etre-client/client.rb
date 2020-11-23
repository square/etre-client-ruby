require 'etre-client/errors'
require 'logger'
require 'rest-client'
require 'json'

module Etre
  class Client
    attr_reader :entity_type, :url

    API_ROOT = "/api/v1"
    META_LABEL_ID = "_id"
    META_LABEL_TYPE = "_type"
    QUERY_TIMEOUT_HEADER = "X-Etre-Query-Timeout"

    def initialize(entity_type:, url:, query_timeout: 5, retry_count: 0, retry_wait: 1, options: {})
      @entity_type = entity_type
      @url = url
      @query_timeout = query_timeout # http request timeout in seconds
      @retry_count = retry_count # retry count on network or API error
      @retry_wait = retry_wait # wait time between retries in seconds
      @options = options

      @logger = Logger.new(STDOUT)
    end

    # query returns an array of entities that satisfy a query.
    def query(query, filter = nil)
      if query.nil? || query.empty?
        raise QueryNotProvided
      end

      # @todo: translate filter to query params

      # Do the normal GET /entities?query unless the query is ~2k characters
      # becuase that brings the entire URL length close to the max supported
      # limit across most HTTP servers. In that case, switch to alternate
      # endpoint to POST the long query.
      if query.length < 2000
        # Always escape the query.
        query = CGI::escape(query)

        begin
          resp = etre_get("/entities/#{@entity_type}?query=#{query}")
        rescue RestClient::ExceptionWithResponse => e
          raise RequestFailed, e.response
        end
      else
        # DO NOT ESCAPE THE QUERY! It's not sent via URL, so no escaping needed.
        begin
          resp = etre_post("/query/#{@entity_type}", query)
        rescue RestClient::ExceptionWithResponse => e
          raise RequestFailed, e.response
        end
      end

      if resp.code != 200
        raise UnexpectedResponseCode, "expected 200, got #{resp.code}"
      end

      return JSON.parse(resp.body)
    end

    # insert inserts an array of entities.
    def insert(entities)
      if entities.nil? || !entities.any?
        raise EntityNotProvided
      end

      entities.each do |e|
        if e.key?(META_LABEL_ID)
          raise EntityIdSet, "entity: #{e}"
        end

        if e.key?(META_LABEL_TYPE) && e[META_LABEL_TYPE] != @entity_type
          raise EntityTypeMismatch, "only valid type is '#{@entity_type}', but " +
            "entity has type '#{e[META_LABEL_TYPE]}'"
        end
      end

      begin
        resp = etre_post("/entities/#{@entity_type}", entities)
      rescue RestClient::ExceptionWithResponse => e
        raise RequestFailed, e.response
      end

      if ![200, 201].include?(resp.code)
        raise UnexpectedResponseCode, "expected 200 or 201, got #{resp.code}"
      end

      return JSON.parse(resp.body)
    end

    # update updates entities with the given patch that satisfy the given query.
    def update(query, patch)
      if query.nil? || query.empty?
        raise QueryNotProvided
      end

      # Always escape the query.
      query = CGI::escape(query)

      if patch.nil? || !patch.any?
        raise PatchNotProvided
      end

      if patch.key?(META_LABEL_ID)
        raise PatchIdSet, "patch: #{patch}"
      end

      if patch.key?(META_LABEL_TYPE) && patch[META_LABEL_TYPE] != @entity_type
        raise EntityTypeMismatch, "only valid type is '#{@entity_type}', but " +
          "patch has type '#{patch[META_LABEL_TYPE]}'"
      end

      begin
        resp = etre_put("/entities/#{@entity_type}?query=#{query}", patch)
      rescue RestClient::ExceptionWithResponse => e
        raise RequestFailed, e.response
      end

      if ![200, 201].include?(resp.code)
        raise UnexpectedResponseCode, "expected 200 or 201, got #{resp.code}"
      end

      return JSON.parse(resp.body)
    end

    # update_one updates the given entity id with the provided patch.
    def update_one(id, patch)
      if id.nil? || id.empty?
        raise IdNotProvided
      end

      if patch.nil? || !patch.any?
        raise PatchNotProvided
      end

      if patch.key?(META_LABEL_ID)
        raise PatchIdSet, "patch: #{patch}"
      end

      if patch.key?(META_LABEL_TYPE) && patch[META_LABEL_TYPE] != @entity_type
        raise EntityTypeMismatch, "only valid type is '#{@entity_type}', but " +
          "patch has type '#{patch[META_LABEL_TYPE]}'"
      end

      begin
        resp = etre_put("/entity/#{@entity_type}/#{id}", patch)
      rescue RestClient::ExceptionWithResponse => e
        raise RequestFailed, e.response
      end

      if ![200, 201].include?(resp.code)
        raise UnexpectedResponseCode, "expected 200 or 201, got #{resp.code}"
      end

      return JSON.parse(resp.body)
    end

    # delete deletes the entities that satisfy the given query.
    def delete(query)
      if query.nil? || query.empty?
        raise QueryNotProvided
      end

      # Always escape the query.
      query = CGI::escape(query)

      begin
        resp = etre_delete("/entities/#{@entity_type}?query=#{query}")
      rescue RestClient::ExceptionWithResponse => e
        raise RequestFailed, e.response
      end

      if resp.code != 200
        raise UnexpectedResponseCode, "expected 200, got #{resp.code}"
      end

      return JSON.parse(resp.body)
    end

    # delete_one deletes the entity with the given id.
    def delete_one(id)
      if id.nil? || id.empty?
        raise IdNotProvided
      end

      begin
        resp = etre_delete("/entity/#{@entity_type}/#{id}")
      rescue RestClient::ExceptionWithResponse => e
        raise RequestFailed, e.response
      end

      if resp.code != 200
        raise UnexpectedResponseCode, "expected 200, got #{resp.code}"
      end

      return JSON.parse(resp.body)
    end

    # labels returns an array of labels for the given entity id.
    def labels(id)
      if id.nil? || id.empty?
        raise IdNotProvided
      end

      begin
        resp = etre_get("/entity/#{@entity_type}/#{id}/labels")
      rescue RestClient::ExceptionWithResponse => e
        raise RequestFailed, e.response
      end

      if resp.code != 200
        raise UnexpectedResponseCode, "expected 200, got #{resp.code}"
      end

      return JSON.parse(resp.body)
    end

    # delete_label deletes the given label on the provided entity id.
    def delete_label(id, label)
      if id.nil? || id.empty?
        raise IdNotProvided
      end

      if label.nil? || label.empty?
        raise LabelNotSet
      end

      begin
        resp = etre_delete("/entity/#{@entity_type}/#{id}/labels/#{label}")
      rescue RestClient::ExceptionWithResponse => e
        raise RequestFailed, e.response
      end

      if resp.code != 200
        raise UnexpectedResponseCode, "expected 200, got #{resp.code}"
      end

      return JSON.parse(resp.body)
    end

    private

    def etre_get(route)
      rest_retry {
        resource_for_route(route).get(
          get_headers,
        )
      }
    end

    def etre_post(route, params = nil)
      rest_retry {
        resource_for_route(route).post(
          params.to_json,
          post_headers,
        )
      }
    end

    def etre_put(route, params = nil)
      rest_retry {
        resource_for_route(route).put(
          params.to_json,
          put_headers,
        )
      }
    end

    def etre_delete(route)
      rest_retry {
        resource_for_route(route).delete(
          delete_headers,
        )
      }
    end

    def get_headers
      {
          :accept => 'application/json',
          :x_etre_query_timeout => @query_timeout
      }
    end

    def post_headers
      get_headers.merge!(:content_type => 'application/json')
    end

    def put_headers
      post_headers
    end

    def delete_headers
      get_headers
    end

    def resource_for_route(route)
      RestClient::Resource.new(
        @url + API_ROOT + route,
        @options
      )
    end

    def parse_response(response)
      JSON.parse(response)
    end

    def rest_retry(&block)
      retries = 0

      begin
        yield
      rescue => e
        if (retries += 1) <= @retry_count
          @logger.warn("Error querying etre (#{e}). Sleeping for #{@retry_wait} seconds before trying again (attmept #{retries}/#{@retry_count}).")
          sleep(@retry_wait)
          retry
        else
          raise
        end
      end
    end
  end
end

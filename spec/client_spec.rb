require 'etre-client'
require 'ostruct'

describe Etre::Client do
  let(:etre_client) { Etre::Client.new(entity_type: "node", url: "http://localhost:3000") }
  let(:get_headers) { {:accept => "application/json", :x_etre_query_timeout => '5s'} }
  let(:post_headers) { get_headers.merge({:content_type => "application/json"}) }
  let(:put_headers) { post_headers }
  let(:delete_headers) { get_headers }
  let(:entity1) { {"_id" => "abc", "foo" => "bar"} }
  let(:entity2) { {"oof" => "rab"} }
  let(:entity3) { {"blah" => "slug"} }
  let(:entity4) { {"_type" => "host", "a" => "b"} }
  let(:response_double) { instance_double(RestClient::Response) }
  let(:resource_double) { instance_double(RestClient::Resource) }

  describe '#query' do
    it "makes GET request when query is short" do
      q = "foo=bar"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entities/#{etre_client.entity_type}?query=#{CGI::escape(q)}"

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return([entity1].to_json)
      expect(resource_double).to receive(:get).with(get_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect(etre_client.query(q)).to eq([entity1])
    end

    it "makes POST request when query is too long" do
      q = "foo=bar," * 300
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/query/#{etre_client.entity_type}"

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return([entity1].to_json)
      expect(resource_double).to receive(:post).with(q.to_json, post_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect(etre_client.query(q)).to eq([entity1])
    end

    it "raises if query is empty" do
      q = ""

      expect{etre_client.query(q)}.to raise_error(Etre::Client::QueryNotProvided)
    end

    it "raises if it gets an unexpected response code" do
      q = "foo=bar"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entities/#{etre_client.entity_type}?query=#{CGI::escape(q)}"

      expect(response_double).to receive(:code).twice.and_return(400)
      expect(resource_double).to receive(:get).with(get_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect{etre_client.query(q)}.to raise_error(Etre::Client::UnexpectedResponseCode)
    end
  end

  describe "#insert" do
    before :each do
      @path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entities/#{etre_client.entity_type}"
    end

    it "inserts entities" do
      entities = [entity2, entity3]

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return(entities.to_json)
      expect(resource_double).to receive(:post).with(entities.to_json, post_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(@path, {}).and_return(resource_double)
      expect(etre_client.insert(entities)).to eq(entities)
    end

    it "raises if an entity has _id set" do
      entities = [entity1, entity2]

      expect{etre_client.insert(entities)}.to raise_error(Etre::Client::EntityIdSet)
    end

    it "raises if an entity has the wrong _type set" do
      entities = [entity2, entity4]

      expect{etre_client.insert(entities)}.to raise_error(Etre::Client::EntityTypeMismatch)
    end

    it "raises if it gets an unexpected response code" do
      entities = [entity2, entity3]

      expect(response_double).to receive(:code).twice.and_return(400)
      expect(resource_double).to receive(:post).with(entities.to_json, post_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(@path, {}).and_return(resource_double)
      expect{etre_client.insert(entities)}.to raise_error(Etre::Client::UnexpectedResponseCode)
    end
  end

  describe "#update" do
    it "updates entities" do
      query = "foo=bar"
      patch = {"foo" => "new"}
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entities/#{etre_client.entity_type}?query=#{CGI::escape(query)}"

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return({}.to_json)
      expect(resource_double).to receive(:put).with(patch.to_json, put_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect(etre_client.update(query, patch)).to eq({})
    end

    it "raises if query is empty" do
      query = ""
      patch = {"foo" => "new"}

      expect{etre_client.update(query, patch)}.to raise_error(Etre::Client::QueryNotProvided)
    end

    it "raises if patch is empty" do
      query = "foo=bar"
      patch = {}

      expect{etre_client.update(query, patch)}.to raise_error(Etre::Client::PatchNotProvided)
    end

    it "raises if _id is set in patch" do
      query = "foo=bar"
      patch = {"_id" => "abc"}

      expect{etre_client.update(query, patch)}.to raise_error(Etre::Client::PatchIdSet)
    end

    it "raises if patch has the wrong _type set" do
      query = "foo=bar"
      patch = {"_type" => "host"}

      expect{etre_client.update(query, patch)}.to raise_error(Etre::Client::EntityTypeMismatch)
    end

    it "raises if it gets an unexpected response code" do
      query = "foo=bar"
      patch = {"foo" => "new"}
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entities/#{etre_client.entity_type}?query=#{CGI::escape(query)}"

      expect(response_double).to receive(:code).twice.and_return(400)
      expect(resource_double).to receive(:put).with(patch.to_json, put_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect{etre_client.update(query, patch)}.to raise_error(Etre::Client::UnexpectedResponseCode)
    end
  end

  describe "#update_one" do
    it "updates an entity" do
      id = "abc"
      patch = {"foo" => "new"}
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entity/#{etre_client.entity_type}/#{id}"

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return({}.to_json)
      expect(resource_double).to receive(:put).with(patch.to_json, put_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect(etre_client.update_one(id, patch)).to eq({})
    end

    it "raises if id is empty" do
      id = ""
      patch = {"foo" => "new"}

      expect{etre_client.update_one(id, patch)}.to raise_error(Etre::Client::IdNotProvided)
    end

    it "raises if patch is empty" do
      id = "abc"
      patch = {}

      expect{etre_client.update_one(id, patch)}.to raise_error(Etre::Client::PatchNotProvided)
    end

    it "raises if _id is set in patch" do
      id = "abc"
      patch = {"_id" => "abc"}

      expect{etre_client.update_one(id, patch)}.to raise_error(Etre::Client::PatchIdSet)
    end

    it "raises if patch has the wrong _type set" do
      id = "abc"
      patch = {"_type" => "host"}

      expect{etre_client.update_one(id, patch)}.to raise_error(Etre::Client::EntityTypeMismatch)
    end

    it "raises if it gets an unexpected response code" do
      id = "abc"
      patch = {"foo" => "new"}
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entity/#{etre_client.entity_type}/#{id}"

      expect(response_double).to receive(:code).twice.and_return(400)
      expect(resource_double).to receive(:put).with(patch.to_json, put_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect{etre_client.update_one(id, patch)}.to raise_error(Etre::Client::UnexpectedResponseCode)
    end
  end

  describe "#delete" do
    it "deletes entities" do
      query = "foo=bar"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entities/#{etre_client.entity_type}?query=#{CGI::escape(query)}"

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return({}.to_json)
      expect(resource_double).to receive(:delete).with(delete_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect(etre_client.delete(query)).to eq({})
    end

    it "raises if query is empty" do
      query = ""

      expect{etre_client.delete(query)}.to raise_error(Etre::Client::QueryNotProvided)
    end

    it "raises if it gets an unexpected response code" do
      query = "foo=bar"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entities/#{etre_client.entity_type}?query=#{CGI::escape(query)}"

      expect(response_double).to receive(:code).twice.and_return(400)
      expect(resource_double).to receive(:delete).with(delete_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect{etre_client.delete(query)}.to raise_error(Etre::Client::UnexpectedResponseCode)
    end
  end

  describe "#delete_one" do
    it "deletes an entity" do
      id = "abc"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entity/#{etre_client.entity_type}/#{id}"

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return({}.to_json)
      expect(resource_double).to receive(:delete).with(delete_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect(etre_client.delete_one(id)).to eq({})
    end

    it "raises if id is empty" do
      id = ""

      expect{etre_client.delete_one(id)}.to raise_error(Etre::Client::IdNotProvided)
    end

    it "raises if it gets an unexpected response code" do
      id = "abc"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entity/#{etre_client.entity_type}/#{id}"

      expect(response_double).to receive(:code).twice.and_return(400)
      expect(resource_double).to receive(:delete).with(delete_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect{etre_client.delete_one(id)}.to raise_error(Etre::Client::UnexpectedResponseCode)
    end
  end

  describe "#labels" do
    it "lists the lables for an entity" do
      id = "abc"
      labels = ["foo1", "foo2"]
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entity/#{etre_client.entity_type}/#{id}/labels"

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return(labels.to_json)
      expect(resource_double).to receive(:get).with(get_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect(etre_client.labels(id)).to eq(labels)
    end

    it "raises if id is empty" do
      id = ""

      expect{etre_client.labels(id)}.to raise_error(Etre::Client::IdNotProvided)
    end

    it "raises if it gets an unexpected response code" do
      id = "abc"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entity/#{etre_client.entity_type}/#{id}/labels"

      expect(response_double).to receive(:code).twice.and_return(400)
      expect(resource_double).to receive(:get).with(get_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect{etre_client.labels(id)}.to raise_error(Etre::Client::UnexpectedResponseCode)
    end
  end

  describe "#delete_label" do
    it "deletes the label on an entity" do
      id = "abc"
      label = "foo"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entity/#{etre_client.entity_type}/#{id}/labels/#{label}"

      expect(response_double).to receive(:code).and_return(200)
      expect(response_double).to receive(:body).and_return({}.to_json)
      expect(resource_double).to receive(:delete).with(delete_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect(etre_client.delete_label(id, label)).to eq({})
    end

    it "raises if id is empty" do
      id = ""
      label = "foo"

      expect{etre_client.delete_label(id, label)}.to raise_error(Etre::Client::IdNotProvided)
    end

    it "raises if label is empty" do
      id = ""
      label = ""

      expect{etre_client.delete_label(id, label)}.to raise_error(Etre::Client::IdNotProvided)
    end

    it "raises if it gets an unexpected response code" do
      id = "abc"
      label = "foo"
      path = "#{etre_client.url}#{Etre::Client::API_ROOT}/entity/#{etre_client.entity_type}/#{id}/labels/#{label}"

      expect(response_double).to receive(:code).twice.and_return(400)
      expect(resource_double).to receive(:delete).with(delete_headers).and_return(response_double)
      expect(RestClient::Resource).to receive(:new).with(path, {}).and_return(resource_double)
      expect{etre_client.delete_label(id, label)}.to raise_error(Etre::Client::UnexpectedResponseCode)
    end
  end
end

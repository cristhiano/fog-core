require 'spec_helper'

describe Fog::Service do
  class TestService < Fog::Service
    requires :generic_api_key
    recognizes :generic_user

    class Real
      attr_reader :options

      def initialize(opts = {})
        @options = opts
      end
    end

    class Mock < Real
    end
  end

  it "properly passes headers" do
    user_agent_hash = {
      "User-Agent" => "Generic Fog Client"
    }
    params = {
      :generic_user => "bob",
      :generic_api_key => "1234",
      :connection_options => {
        :headers => user_agent_hash
      }
    }
    service = TestService.new(params)

    assert_equal user_agent_hash, service.options[:connection_options][:headers]
  end

  describe "when created with a Hash" do
    it "raises for required argument that are missing" do
      assert_raises(ArgumentError) { TestService.new({}) }
    end

    it "converts String keys to be Symbols" do
      service = TestService.new "generic_api_key" => "abc"
      assert_includes service.options.keys, :generic_api_key
    end

    it "removes keys with `nil` values" do
      service = TestService.new :generic_api_key => "abc", :generic_user => nil
      refute_includes service.options.keys, :generic_user
    end

    it "converts number String values with to_i" do
      service = TestService.new :generic_api_key => "3421"
      assert_equal 3421, service.options[:generic_api_key]
    end

    it "converts 'true' String values to TrueClass" do
      service = TestService.new :generic_api_key => "true"
      assert_equal true, service.options[:generic_api_key]
    end

    it "converts 'false' String values to FalseClass" do
      service = TestService.new :generic_api_key => "false"
      assert_equal false, service.options[:generic_api_key]
    end

    it "warns for unrecognised options" do
      bad_options = { :generic_api_key => "abc", :bad_option => "bad value" }
      logger = Minitest::Mock.new
      logger.expect :warning, nil, ["Unrecognized arguments: bad_option"]
      Fog.stub_const :Logger, logger do
        TestService.new(bad_options)
      end
      logger.verify
    end
  end

  describe "when creating and mocking is disabled" do
    it "returns mocked service" do
      Fog.stub :mocking?, false do
        service = TestService.new(:generic_api_key => "abc")
        service.must_be_instance_of TestService::Real
      end
    end
  end

  describe "when creating and mocking is enabled" do
    it "returns mocked service" do
      Fog.stub :mocking?, true do
        service = TestService.new(:generic_api_key => "abc")
        service.must_be_instance_of TestService::Mock
      end
    end
  end

  describe "when no credentials are provided" do
    it "uses the global values" do
      @global_credentials = {
        :generic_user => "fog",
        :generic_api_key => "fog"
      }

      Fog.stub :credentials, @global_credentials do
        @service = TestService.new
        assert_equal @service.options, @global_credentials
      end
    end
  end

  describe "when credentials are provided as settings" do
    it "merges the global values into settings" do
      @settings = {
        :generic_user => "fog"
      }
      @global_credentials = {
        :generic_user => "bob",
        :generic_api_key => "fog"
      }

      Fog.stub :credentials, @global_credentials do
        @service = TestService.new(@settings)
        assert_equal @service.options[:generic_user], "fog"
        assert_equal @service.options[:generic_api_key], "fog"
      end
    end
  end

  describe "when config object can configure the service itself" do
    it "ignores the global and it's values" do
      @config = MiniTest::Mock.new
      def @config.config_service?;  true; end
      def @config.==(other); object_id == other.object_id; end

      Fog.stub :credentials, lambda { raise "Accessing global!" } do
        @service = TestService.new(@config)
        assert_equal @config, @service.options
      end
    end
  end
end

require "test_helper"

module ActiveUsage
  module Web
    class ConfigurationsControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        ENV["ACTIVEUSAGE_PASSWORD"] = "secret"

        @configuration = active_usage_web_configurations(:one)
      end

      test "should get index" do
        get configurations_url, headers: headers

        assert_response :success
      end

      test "should get new" do
        get new_configuration_url, headers: headers

        assert_response :success
      end

      test "should create configuration" do
        assert_difference("Configuration.count") do
          post configurations_url, params: { configuration: { compute_cost_per_hour: @configuration.compute_cost_per_hour, database_cost_per_hour: @configuration.database_cost_per_hour } }, headers: headers
        end

        assert_redirected_to configuration_url(Configuration.last)
      end

      test "should show configuration" do
        get configuration_url(@configuration), headers: headers

        assert_response :success
      end

      test "should get edit" do
        get edit_configuration_url(@configuration), headers: headers

        assert_response :success
      end

      test "should update configuration" do
        patch configuration_url(@configuration), params: { configuration: { compute_cost_per_hour: @configuration.compute_cost_per_hour, database_cost_per_hour: @configuration.database_cost_per_hour } }, headers: headers

        assert_redirected_to configuration_url(@configuration)
      end

      test "should destroy configuration" do
        assert_difference("Configuration.count", -1) do
          delete configuration_url(@configuration), headers: headers
        end

        assert_redirected_to configurations_url
      end

      private

      def headers
        {
          "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("activeusage", "secret")
        }
      end
    end
  end
end

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
        get configurations_url, headers: auth_headers

        assert_response :success
      end

      test "should get new" do
        get new_configuration_url, headers: auth_headers

        assert_response :success
      end

      test "should create configuration" do
        assert_difference("Configuration.count") do
          post configurations_url,
            params: { configuration: { compute_cost_per_hour: @configuration.compute_cost_per_hour, database_cost_per_hour: @configuration.database_cost_per_hour } },
            headers: auth_headers
        end

        assert_redirected_to configurations_url
      end

      test "should not create configuration with invalid params" do
        assert_no_difference("Configuration.count") do
          post configurations_url,
            params: { configuration: { compute_cost_per_hour: 0, database_cost_per_hour: nil } },
            headers: auth_headers
        end

        assert_response :unprocessable_content
      end

      private

      def auth_headers
        { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("activeusage", "secret") }
      end
    end
  end
end

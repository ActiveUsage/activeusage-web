require "test_helper"

module ActiveUsage
  module Web
    class CostRatesControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        setup_auth
        @cost_rate = active_usage_web_cost_rates(:one)
      end

      test "should get index" do
        get cost_rates_url, headers: auth_headers

        assert_response :success
        assert_select "h1.au-page-title", text: "Cost rates"
        assert_select ".au-rate-label", text: "Compute"
        assert_select ".au-rate-label", text: "Database"
      end

      test "should get new" do
        get new_cost_rate_url, headers: auth_headers

        assert_response :success
        assert_select "h1.au-page-title", text: "Update cost rates"
        assert_select ".au-form-label", text: "Compute cost per hour"
        assert_select ".au-form-label", text: "Database cost per hour"
        assert_select ".au-input-affix", text: "$"
      end

      test "should create cost rate" do
        assert_difference("CostRate.count") do
          post cost_rates_url,
            params: { cost_rate: { compute_cost_per_hour: @cost_rate.compute_cost_per_hour, database_cost_per_hour: @cost_rate.database_cost_per_hour } },
            headers: auth_headers
        end

        assert_redirected_to cost_rates_url
      end

      test "should not create cost rate with invalid params" do
        assert_no_difference("CostRate.count") do
          post cost_rates_url,
            params: { cost_rate: { compute_cost_per_hour: 0, database_cost_per_hour: nil } },
            headers: auth_headers
        end

        assert_response :unprocessable_content
      end

      test "onboarding banner is suppressed on cost_rates pages" do
        CostRate.delete_all
        get cost_rates_url, headers: auth_headers
        assert_select ".au-onboarding-banner", count: 0

        get new_cost_rate_url, headers: auth_headers
        assert_select ".au-onboarding-banner", count: 0
      end
    end
  end
end

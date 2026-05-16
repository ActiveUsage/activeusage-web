require "test_helper"

module ActiveUsage
  module Web
    class HomeControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        setup_auth
        Event.delete_all
        SqlQuery.delete_all
        CostRate.delete_all
      end

      test "returns 401 without auth" do
        get root_url
        assert_response :unauthorized
      end

      test "renders 200 with auth on empty DB" do
        get root_url, headers: auth_headers
        assert_response :success
      end

      test "renders 200 with data" do
        Event.create!(event_type: "request", name: "PostsController#index", started_at: 1.hour.ago, finished_at: 1.hour.ago + 0.1,
                            duration_ms: 100, sql_duration_ms: 0, sql_calls: 0, allocations: 0, external_calls: 0,
                            retry_count: 0, tags: {}, estimated_cost: 1.0, cost_breakdown: {}, window_started_at: 1.hour.ago)
        get root_url, headers: auth_headers
        assert_response :success
        assert_select "h1.au-page-title", text: "Overview"
        assert_select ".au-stat-label", text: /Tracked events/i
        assert_select ".au-stat-label", text: /Estimated cost/i
        assert_select ".au-metric-name", text: "PostsController#index"
      end

      test "accepts range and event_type params" do
        get root_url(range: "7d", event_type: "request"), headers: auth_headers
        assert_response :success
      end

      test "ignores invalid range and event_type params" do
        get root_url(range: "garbage", event_type: "nope"), headers: auth_headers
        assert_response :success
      end

      test "shows onboarding banner when no cost rate is configured" do
        get root_url, headers: auth_headers
        assert_response :success
        assert_select ".au-onboarding-banner"
        assert_select ".au-onboarding-banner-link", text: /Set up/
      end

      test "hides onboarding banner once a cost rate exists" do
        CostRate.create!(compute_cost_per_hour: 1.0, database_cost_per_hour: 2.0)
        get root_url, headers: auth_headers
        assert_response :success
        assert_select ".au-onboarding-banner", count: 0
      end
    end
  end
end

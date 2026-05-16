require "test_helper"

module ActiveUsage
  module Web
    class TrendsControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        setup_auth
        Event.delete_all
        SqlQuery.delete_all
      end

      test "returns 401 without auth" do
        get trends_url
        assert_response :unauthorized
      end

      test "renders 200 on empty DB" do
        get trends_url, headers: auth_headers
        assert_response :success
      end

      test "renders for each valid period" do
        %w[1h 24h 7d 30d].each do |p|
          get trends_url(period: p), headers: auth_headers
          assert_response :success, "period=#{p}"
        end
      end

      test "ignores invalid period" do
        get trends_url(period: "garbage"), headers: auth_headers
        assert_response :success
      end

      test "renders with event data" do
        Event.create!(event_type: "request", name: "PostsController#show", started_at: 1.day.ago, finished_at: 1.day.ago + 0.1,
                            duration_ms: 100, sql_duration_ms: 0, sql_calls: 0, allocations: 0, external_calls: 0,
                            retry_count: 0, tags: {}, estimated_cost: 1.0, cost_breakdown: {}, window_started_at: 1.day.ago)
        get trends_url, headers: auth_headers
        assert_response :success
        assert_select "h1.au-page-title", text: "Trends"
        assert_select ".au-chart-bars"
        assert_select ".au-comp-table"
        assert_select ".au-comp-name", text: "PostsController#show"
      end
    end
  end
end

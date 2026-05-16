require "test_helper"

module ActiveUsage
  module Web
    class WorkloadsControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        setup_auth
        Event.delete_all
        SqlQuery.delete_all
      end

      test "returns 401 without auth" do
        get workloads_url
        assert_response :unauthorized
      end

      test "renders 200 on empty DB" do
        get workloads_url, headers: auth_headers
        assert_response :success
      end

      test "renders with workloads data" do
        3.times do |i|
          Event.create!(event_type: "request", name: "Workload#{i}", started_at: 1.hour.ago, finished_at: 1.hour.ago + 0.1,
                              duration_ms: 100, sql_duration_ms: 0, sql_calls: 0, allocations: 0, external_calls: 0,
                              retry_count: 0, tags: {}, estimated_cost: 1.0 * i, cost_breakdown: {}, window_started_at: 1.hour.ago)
        end
        get workloads_url, headers: auth_headers
        assert_response :success
        assert_select "h1.au-page-title", text: "Workloads"
        assert_select ".au-metric-name", text: "Workload2"
        assert_select ".au-filter-bar"
      end

      test "honors pagination via page param" do
        get workloads_url(page: 2), headers: auth_headers
        assert_response :success
      end
    end
  end
end

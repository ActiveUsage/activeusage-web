require "test_helper"

module ActiveUsage
  module Web
    class EventsControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        setup_auth
        Event.delete_all
        SqlQuery.delete_all
      end

      test "returns 401 without auth" do
        get events_url
        assert_response :unauthorized
      end

      test "renders 200 on empty DB" do
        get events_url, headers: auth_headers
        assert_response :success
      end

      test "renders with paginated events" do
        15.times do |i|
          Event.create!(event_type: "request", name: "Event#{i}", started_at: (i + 1).minutes.ago, finished_at: (i + 1).minutes.ago + 0.1,
                              duration_ms: 100, sql_duration_ms: 0, sql_calls: 0, allocations: 0, external_calls: 0,
                              retry_count: 0, tags: {}, estimated_cost: 0.1, cost_breakdown: {}, window_started_at: (i + 1).minutes.ago)
        end
        get events_url, headers: auth_headers
        assert_response :success
        assert_select "h1.au-page-title", text: "Events"
        assert_select ".au-event-name", text: "Event0"
        assert_select ".au-pagination"

        get events_url(page: 2), headers: auth_headers
        assert_response :success
      end
    end
  end
end

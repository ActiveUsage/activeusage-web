require "test_helper"

module ActiveUsage
  module Web
    class SqlQueriesControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        setup_auth
        Event.delete_all
        SqlQuery.delete_all
      end

      test "returns 401 without auth" do
        get sql_queries_url
        assert_response :unauthorized
      end

      test "renders 200 on empty DB" do
        get sql_queries_url, headers: auth_headers
        assert_response :success
      end

      test "renders with sql query data" do
        SqlQuery.create!(fingerprint: "SELECT * FROM users", adapter_name: "SQLite", duration_ms: 1.0, calls: 1,
                               db_cost: 0.001, event_name: "X#y", event_type: "request",
                               finished_at: 1.hour.ago, window_started_at: 1.hour.ago)
        get sql_queries_url, headers: auth_headers
        assert_response :success
        assert_select "h1.au-page-title", text: "SQL Queries"
        assert_select ".au-sql-fp", text: /SELECT \* FROM users/
        assert_select ".au-badge--sql", text: "SELECT"
      end
    end
  end
end

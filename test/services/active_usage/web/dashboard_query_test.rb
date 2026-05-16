require "test_helper"

module ActiveUsage
  module Web
    class DashboardQueryTest < ActiveSupport::TestCase
      setup do
        Event.delete_all
        SqlQuery.delete_all
      end

      # ─── initialize / validation ───────────────────────────────

      test "defaults to 24h range and all event_type" do
        q = DashboardQuery.new
        assert_equal "24h", q.range
        assert_equal "all", q.event_type
      end

      test "falls back to 24h for unknown range" do
        q = DashboardQuery.new(range: "1y")
        assert_equal "24h", q.range
      end

      test "falls back to all for unknown event_type" do
        q = DashboardQuery.new(event_type: "garbage")
        assert_equal "all", q.event_type
      end

      test "accepts all valid ranges" do
        %w[1h 24h 7d 30d].each do |r|
          assert_equal r, DashboardQuery.new(range: r).range
        end
      end

      test "accepts all valid event_types" do
        %w[all request job task].each do |t|
          assert_equal t, DashboardQuery.new(event_type: t).event_type
        end
      end

      # ─── summary ───────────────────────────────────────────────

      test "summary counts events, sums cost, returns most recent finish" do
        build_event(name: "A", finished_at: 1.hour.ago,  estimated_cost: 1.0)
        build_event(name: "B", finished_at: 2.hours.ago, estimated_cost: 2.5)

        s = DashboardQuery.new.summary
        assert_equal 2, s[:events_count]
        assert_in_delta 3.5, s[:total_estimated_cost]
        assert_in_delta 1.hour.ago.to_f, s[:last_event_at].to_f, 60
      end

      test "summary respects range filter" do
        build_event(finished_at: 30.minutes.ago, estimated_cost: 1.0)
        build_event(finished_at: 5.hours.ago,    estimated_cost: 9.0)

        within_1h = DashboardQuery.new(range: "1h").summary
        within_24h = DashboardQuery.new(range: "24h").summary

        assert_equal 1, within_1h[:events_count]
        assert_equal 2, within_24h[:events_count]
      end

      test "summary respects event_type filter" do
        build_event(event_type: "request", finished_at: 1.hour.ago)
        build_event(event_type: "job",     finished_at: 1.hour.ago)

        only_requests = DashboardQuery.new(event_type: "request").summary
        assert_equal 1, only_requests[:events_count]
      end

      test "summary on empty DB returns zeros and nil" do
        s = DashboardQuery.new.summary
        assert_equal 0, s[:events_count]
        assert_equal 0.0, s[:total_estimated_cost]
        assert_nil s[:last_event_at]
      end

      # ─── workloads ─────────────────────────────────────────────

      test "top_workloads aggregates by name and orders by total_cost DESC" do
        build_event(name: "PostsController#index", finished_at: 1.hour.ago, estimated_cost: 1.0)
        build_event(name: "PostsController#index", finished_at: 2.hours.ago, estimated_cost: 2.0)
        build_event(name: "UsersController#show",  finished_at: 1.hour.ago, estimated_cost: 0.5)

        rows = DashboardQuery.new.top_workloads(limit: 5)
        assert_equal 2, rows.size
        assert_equal "PostsController#index", rows[0][:name]
        assert_in_delta 3.0, rows[0][:total_cost]
        assert_equal 2, rows[0][:events_count]
      end

      test "top_workloads honors limit" do
        5.times { |i| build_event(name: "W#{i}", finished_at: 1.hour.ago, estimated_cost: i.to_f) }
        assert_equal 2, DashboardQuery.new.top_workloads(limit: 2).size
      end

      test "all_workloads returns all aggregated rows" do
        3.times { |i| build_event(name: "W#{i}", finished_at: 1.hour.ago, estimated_cost: 1.0) }
        assert_equal 3, DashboardQuery.new.all_workloads.size
      end

      test "workload rows include event_type (via MIN aggregation)" do
        build_event(name: "X", event_type: "job", finished_at: 1.hour.ago)
        rows = DashboardQuery.new.all_workloads
        assert_equal "job", rows.first[:event_type]
      end

      # ─── SQL queries ───────────────────────────────────────────

      test "top_sql_queries aggregates by fingerprint and orders by db_cost DESC" do
        build_sql_query(fingerprint: "SELECT * FROM users", finished_at: 1.hour.ago, db_cost: 0.5)
        build_sql_query(fingerprint: "SELECT * FROM users", finished_at: 2.hours.ago, db_cost: 1.5)
        build_sql_query(fingerprint: "SELECT * FROM posts", finished_at: 1.hour.ago, db_cost: 0.1)

        rows = DashboardQuery.new.top_sql_queries(limit: 5)
        assert_equal 2, rows.size
        assert_equal "SELECT * FROM users", rows[0][:fingerprint]
        assert_in_delta 2.0, rows[0][:db_cost]
      end

      test "top_sql_queries extracts query_type from fingerprint prefix" do
        build_sql_query(fingerprint: "SELECT 1", finished_at: 1.hour.ago)
        build_sql_query(fingerprint: "UPDATE users SET x = 1", finished_at: 1.hour.ago)
        build_sql_query(fingerprint: "INSERT INTO foo VALUES (1)", finished_at: 1.hour.ago)

        rows = DashboardQuery.new.all_sql_queries
        types = rows.map { |r| r[:query_type] }.sort
        assert_equal %w[INSERT SELECT UPDATE], types
      end

      test "top_sql_queries extracts relation_name for common patterns" do
        cases = {
          "SELECT * FROM users WHERE id = ?"           => "users",
          "SELECT * FROM posts JOIN authors ON ..."    => "posts",
          "UPDATE accounts SET active = ?"             => "accounts",
          "INSERT INTO comments VALUES (?)"            => "comments",
          "DELETE FROM sessions WHERE expired_at < ?"  => "sessions"
        }
        cases.each do |fp, _expected|
          build_sql_query(fingerprint: fp, finished_at: 1.hour.ago)
        end

        rows = DashboardQuery.new.all_sql_queries.index_by { |r| r[:fingerprint] }
        cases.each { |fp, expected| assert_equal expected, rows[fp][:relation_name], fp }
      end

      test "sql query range filter excludes old fingerprints" do
        build_sql_query(fingerprint: "SELECT 1", finished_at: 30.minutes.ago)
        build_sql_query(fingerprint: "SELECT 2", finished_at: 5.hours.ago)

        assert_equal 1, DashboardQuery.new(range: "1h").all_sql_queries.size
        assert_equal 2, DashboardQuery.new(range: "24h").all_sql_queries.size
      end

      test "sql query event_type filter" do
        build_sql_query(fingerprint: "SELECT 1", event_type: "request", finished_at: 1.hour.ago)
        build_sql_query(fingerprint: "SELECT 2", event_type: "job",     finished_at: 1.hour.ago)

        assert_equal 1, DashboardQuery.new(event_type: "request").all_sql_queries.size
      end

      # ─── events listing ────────────────────────────────────────

      test "events_count counts events in range" do
        build_event(finished_at: 30.minutes.ago)
        build_event(finished_at: 5.hours.ago)
        assert_equal 1, DashboardQuery.new(range: "1h").events_count
      end

      test "all_events orders by finished_at DESC and paginates" do
        3.times { |i| build_event(name: "E#{i}", finished_at: (i + 1).hours.ago) }
        page = DashboardQuery.new.all_events(page: 1, per_page: 2)
        names = page.map(&:name)
        assert_equal %w[E0 E1], names  # E0 is newest (1h ago)
      end

      test "all_events page 2 returns rest" do
        3.times { |i| build_event(name: "E#{i}", finished_at: (i + 1).hours.ago) }
        page = DashboardQuery.new.all_events(page: 2, per_page: 2)
        assert_equal %w[E2], page.map(&:name)
      end

      private

      def build_event(name: "TestController#index", event_type: "request", finished_at: Time.now, estimated_cost: 0.0)
        Event.create!(
          event_type:        event_type,
          name:              name,
          started_at:        finished_at - 0.1,
          finished_at:       finished_at,
          duration_ms:       100.0,
          sql_duration_ms:   0.0,
          sql_calls:         0,
          allocations:       0,
          external_calls:    0,
          retry_count:       0,
          tags:              {},
          estimated_cost:    estimated_cost,
          cost_breakdown:    {},
          window_started_at: finished_at
        )
      end

      def build_sql_query(fingerprint:, finished_at:, event_type: "request", db_cost: 0.0, duration_ms: 1.0, calls: 1, event_name: "TestController#index")
        SqlQuery.create!(
          fingerprint:       fingerprint,
          adapter_name:      "SQLite",
          duration_ms:       duration_ms,
          calls:             calls,
          db_cost:           db_cost,
          event_name:        event_name,
          event_type:        event_type,
          finished_at:       finished_at,
          window_started_at: finished_at
        )
      end
    end
  end
end

require "test_helper"

module ActiveUsage
  module Web
    class ActiveRecordAdapterTest < ActiveSupport::TestCase
      class FakeEvent
        attr_reader :type, :name, :started_at, :finished_at, :allocations,
                    :retry_count, :tags, :sql_queries, :window_started_at

        def initialize(type:, name:, started_at:, finished_at:, allocations:,
                       retry_count:, tags:, sql_queries:, window_started_at:)
          @type, @name, @started_at, @finished_at = type, name, started_at, finished_at
          @allocations, @retry_count = allocations, retry_count
          @tags, @sql_queries, @window_started_at = tags, sql_queries, window_started_at
        end
      end

      setup do
        Event.delete_all
        SqlQuery.delete_all
        CostRate.delete_all
        @adapter = ActiveRecordAdapter.new
      end

      def build_event(**overrides)
        defaults = {
          type:              :request,
          name:              "PostsController#index",
          started_at:        Time.now - 0.1,
          finished_at:       Time.now,
          allocations:       1000,
          retry_count:       0,
          tags:              { env: "test" },
          sql_queries:       [],
          window_started_at: Time.now
        }
        FakeEvent.new(**defaults.merge(overrides))
      end

      def build_sql_query(fingerprint: "SELECT * FROM users", total_duration_ms: 10.0, calls: 1, adapter_name: "SQLite", symbols: true)
        if symbols
          { fingerprint: fingerprint, total_duration_ms: total_duration_ms, calls: calls, adapter_name: adapter_name }
        else
          { "fingerprint" => fingerprint, "total_duration_ms" => total_duration_ms, "calls" => calls, "adapter_name" => adapter_name }
        end
      end

      # ─── empty / nil inputs ────────────────────────────────────

      test "record with empty array does nothing" do
        assert_no_difference -> { Event.count } do
          @adapter.record([])
        end
      end

      test "record with nil treats as empty array" do
        assert_nothing_raised { @adapter.record(nil) }
        assert_equal 0, Event.count
      end

      test "record accepts a single event (not array)" do
        @adapter.record(build_event)
        assert_equal 1, Event.count
      end

      # ─── basic row insertion ───────────────────────────────────

      test "record inserts one Event per event" do
        @adapter.record([ build_event, build_event ])
        assert_equal 2, Event.count
      end

      test "record persists basic event fields" do
        event = build_event(name: "Test#action", type: :job, allocations: 500)
        @adapter.record([ event ])
        row = Event.last

        assert_equal "Test#action", row.name
        assert_equal "job",         row.event_type
        assert_equal 500,           row.allocations
        assert_equal({ "env" => "test" }, row.tags)
      end

      test "record computes duration_ms from started_at and finished_at" do
        started  = Time.now - 0.250  # 250ms
        finished = Time.now
        @adapter.record([ build_event(started_at: started, finished_at: finished) ])

        row = Event.last
        assert_in_delta 250.0, row.duration_ms, 1.0
      end

      test "record computes duration_ms as exact difference when started_at == finished_at" do
        t = Time.now
        @adapter.record([ build_event(started_at: t, finished_at: t) ])
        assert_equal 0.0, Event.last.duration_ms
      end

      # ─── SQL queries ───────────────────────────────────────────

      test "record inserts SqlQuery rows when sql_queries present" do
        event = build_event(sql_queries: [
          build_sql_query(fingerprint: "SELECT 1", total_duration_ms: 5.0, calls: 2),
          build_sql_query(fingerprint: "UPDATE x", total_duration_ms: 3.0, calls: 1)
        ])
        @adapter.record([ event ])

        assert_equal 1, Event.count
        assert_equal 2, SqlQuery.count
      end

      test "record propagates event metadata (name, type, finished_at, window_started_at) into sql rows" do
        finished = Time.parse("2026-05-15 12:00:00 UTC")
        window   = Time.parse("2026-05-15 11:55:00 UTC")
        event = build_event(
          name: "X#y", type: :task,
          finished_at: finished, started_at: finished - 0.1,
          window_started_at: window,
          sql_queries: [ build_sql_query ]
        )
        @adapter.record([ event ])

        sql = SqlQuery.last
        assert_equal "X#y",   sql.event_name
        assert_equal "task",  sql.event_type
        assert_in_delta finished.to_f, sql.finished_at.to_f, 1
        assert_in_delta window.to_f,   sql.window_started_at.to_f, 1
      end

      test "record skips SQL queries with empty fingerprint" do
        event = build_event(sql_queries: [
          build_sql_query(fingerprint: ""),
          build_sql_query(fingerprint: "SELECT 1")
        ])
        @adapter.record([ event ])
        assert_equal 1, SqlQuery.count
      end

      test "record accepts string-keyed sql_queries hashes (e.g. from JSON deserialization)" do
        event = build_event(sql_queries: [ build_sql_query(symbols: false) ])
        @adapter.record([ event ])

        sql = SqlQuery.last
        assert_equal "SELECT * FROM users", sql.fingerprint
        assert_equal 10.0, sql.duration_ms
        assert_equal "SQLite", sql.adapter_name
      end

      test "record updates sql_duration_ms and sql_calls aggregates on event row" do
        event = build_event(sql_queries: [
          build_sql_query(total_duration_ms: 5.0, calls: 2),
          build_sql_query(fingerprint: "SELECT 2", total_duration_ms: 3.5, calls: 1)
        ])
        @adapter.record([ event ])

        row = Event.last
        assert_in_delta 8.5, row.sql_duration_ms
        assert_equal 3, row.sql_calls
      end

      # ─── cost estimation ──────────────────────────────────────

      test "without CostRate, costs are zero but rows are still inserted" do
        event = build_event(sql_queries: [ build_sql_query ])
        @adapter.record([ event ])

        assert_equal 1, Event.count
        assert_equal 1, SqlQuery.count
        assert_equal 0.0, Event.last.estimated_cost
        assert_equal 0.0, SqlQuery.last.db_cost
      end

      test "with CostRate, compute and db costs are estimated and combined" do
        CostRate.create!(compute_cost_per_hour: 3.6, database_cost_per_hour: 7.2)
        # 1000ms compute at $3.6/h = 3.6 * (1000/3_600_000) = 0.001
        # 1000ms db at $7.2/h     = 7.2 * (1000/3_600_000) = 0.002
        event = build_event(
          started_at: Time.now - 1.0, finished_at: Time.now,
          sql_queries: [ build_sql_query(total_duration_ms: 1000.0) ]
        )
        @adapter.record([ event ])

        row = Event.last
        assert_in_delta 0.003, row.estimated_cost.to_f, 0.0001
        assert_in_delta 0.001, row.cost_breakdown["compute"], 0.0001
        assert_in_delta 0.002, row.cost_breakdown["db"], 0.0001
      end

      test "preserves precision for tiny costs (low rate × short event)" do
        # $0.01/h × 100ms compute = ~2.78e-7 — must survive rounding, not collapse to $0
        CostRate.create!(compute_cost_per_hour: 0.01, database_cost_per_hour: 0.01)
        event = build_event(started_at: Time.now - 0.1, finished_at: Time.now)
        @adapter.record([ event ])

        row = Event.last
        assert_operator row.estimated_cost.to_f, :>, 0.0, "tiny cost was rounded to zero"
        assert_in_delta 2.78e-7, row.estimated_cost.to_f, 1e-8
      end

      test "with CostRate, db_cost is allocated proportionally across SQL fingerprints" do
        # Minimal compute, real db rate; 1000ms total sql, split 750/250 between two fingerprints
        # db_cost = 7.2 * 1000/3_600_000 = 0.002 ; fp1 gets 75% = 0.0015, fp2 gets 25% = 0.0005
        CostRate.create!(compute_cost_per_hour: 0.01, database_cost_per_hour: 7.2)
        event = build_event(
          started_at: Time.now - 1.0, finished_at: Time.now,
          sql_queries: [
            build_sql_query(fingerprint: "A", total_duration_ms: 750.0),
            build_sql_query(fingerprint: "B", total_duration_ms: 250.0)
          ]
        )

        @adapter.record([ event ])
        rows = SqlQuery.order(:fingerprint).to_a
        assert_in_delta 0.0015, rows[0].db_cost, 0.0001
        assert_in_delta 0.0005, rows[1].db_cost, 0.0001
      end

      # ─── adapter API ──────────────────────────────────────────

      test "clear! and shutdown! exist and do not raise" do
        assert_nothing_raised { @adapter.clear! }
        assert_nothing_raised { @adapter.shutdown! }
      end

      # ─── resilience ───────────────────────────────────────────

      test "insert_events swallows StatementInvalid (table missing scenario)" do
        with_stubbed_method(Event, :insert_all, ->(_) { raise ActiveRecord::StatementInvalid, "no such table" }) do
          assert_nothing_raised { @adapter.record([ build_event ]) }
        end
      end

      test "insert_sql_queries logs but does not raise on StatementInvalid" do
        with_stubbed_method(SqlQuery, :insert_all, ->(_) { raise ActiveRecord::StatementInvalid, "boom" }) do
          assert_nothing_raised do
            @adapter.record([ build_event(sql_queries: [ build_sql_query ]) ])
          end
        end
      end

      private

      def with_stubbed_method(klass, method_name, replacement)
        original = klass.method(method_name)
        klass.singleton_class.send(:define_method, method_name, &replacement)
        yield
      ensure
        klass.singleton_class.send(:define_method, method_name, &original)
      end
    end
  end
end

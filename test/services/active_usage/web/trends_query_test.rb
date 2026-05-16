require "test_helper"

module ActiveUsage
  module Web
    class TrendsQueryTest < ActiveSupport::TestCase
      setup do
        Event.delete_all
      end

      # ─── initialize / validation ───────────────────────────────

      test "defaults to 30d period and all event_type" do
        q = TrendsQuery.new
        assert_equal "30d", q.period
        assert_equal "all", q.event_type
      end

      test "falls back to 30d for unknown period" do
        assert_equal "30d", TrendsQuery.new(period: "bogus").period
      end

      test "accepts all four valid periods" do
        %w[1h 24h 7d 30d].each do |p|
          assert_equal p, TrendsQuery.new(period: p).period
        end
      end

      # ─── period boundaries ─────────────────────────────────────

      test "current_period_start is one period ago" do
        q = TrendsQuery.new(period: "24h")
        assert_in_delta 24.hours.ago.to_f, q.current_period_start.to_f, 60
      end

      test "previous_period_start is two periods ago" do
        q = TrendsQuery.new(period: "24h")
        assert_in_delta 48.hours.ago.to_f, q.previous_period_start.to_f, 60
      end

      # ─── chart_data: bucket counts ─────────────────────────────

      test "chart_data 1h returns 12 five-minute buckets" do
        buckets = TrendsQuery.new(period: "1h").chart_data
        assert_equal 12, buckets.size
      end

      test "chart_data 24h returns 24 hourly buckets" do
        buckets = TrendsQuery.new(period: "24h").chart_data
        assert_equal 24, buckets.size
      end

      test "chart_data 7d returns 7 or 8 daily buckets (range inclusive of today)" do
        buckets = TrendsQuery.new(period: "7d").chart_data
        # Range from 7.days.ago.to_date..Date.today is 8 dates inclusive
        assert_includes [ 7, 8 ], buckets.size
      end

      test "chart_data 30d returns 30 or 31 daily buckets" do
        buckets = TrendsQuery.new(period: "30d").chart_data
        assert_includes [ 30, 31 ], buckets.size
      end

      test "every bucket has expected keys" do
        bucket = TrendsQuery.new(period: "1h").chart_data.first
        %i[label total_cost events_count prev_total_cost prev_events_count].each do |k|
          assert bucket.key?(k), "missing #{k}"
        end
      end

      # ─── chart_data: bucketing logic ───────────────────────────

      test "events in current period are summed into current totals" do
        build_event(finished_at: 30.minutes.ago, estimated_cost: 0.5)
        build_event(finished_at: 45.minutes.ago, estimated_cost: 0.7)

        buckets = TrendsQuery.new(period: "1h").chart_data
        total_current = buckets.sum { |b| b[:total_cost] }
        assert_in_delta 1.2, total_current
      end

      test "events in previous period populate prev_total_cost" do
        # 1h period: prev period is 1-2h ago
        build_event(finished_at: 90.minutes.ago, estimated_cost: 0.3)

        buckets = TrendsQuery.new(period: "1h").chart_data
        total_prev    = buckets.sum { |b| b[:prev_total_cost] }
        total_current = buckets.sum { |b| b[:total_cost] }
        assert_in_delta 0.3, total_prev
        assert_in_delta 0.0, total_current
      end

      test "events outside both periods are excluded" do
        build_event(finished_at: 50.hours.ago, estimated_cost: 10.0) # outside 24h+prev24h
        buckets = TrendsQuery.new(period: "24h").chart_data
        assert_equal 0.0, buckets.sum { |b| b[:total_cost] }
        assert_equal 0.0, buckets.sum { |b| b[:prev_total_cost] }
      end

      test "chart_data on empty DB has all zero totals" do
        buckets = TrendsQuery.new(period: "1h").chart_data
        assert buckets.all? { |b| b[:total_cost] == 0.0 && b[:prev_total_cost] == 0.0 }
      end

      # ─── comparison ────────────────────────────────────────────

      test "comparison shows workloads with current and previous costs side by side" do
        build_event(name: "A", finished_at: 1.day.ago,  estimated_cost: 5.0)  # current 7d
        build_event(name: "A", finished_at: 8.days.ago, estimated_cost: 3.0)  # prev 7d
        build_event(name: "B", finished_at: 1.day.ago,  estimated_cost: 1.0)

        rows = TrendsQuery.new(period: "7d").comparison.index_by { |r| r[:name] }
        assert_in_delta 5.0, rows["A"][:current_cost]
        assert_in_delta 3.0, rows["A"][:previous_cost]
        assert_in_delta 1.0, rows["B"][:current_cost]
        assert_in_delta 0.0, rows["B"][:previous_cost]
      end

      test "comparison delta_pct is correct percentage increase" do
        build_event(name: "X", finished_at: 1.day.ago,  estimated_cost: 6.0)
        build_event(name: "X", finished_at: 8.days.ago, estimated_cost: 4.0)

        row = TrendsQuery.new(period: "7d").comparison.first
        assert_equal 50.0, row[:delta_pct]
      end

      test "comparison delta_pct is nil when previous cost is zero" do
        build_event(name: "NewWorkload", finished_at: 1.day.ago, estimated_cost: 5.0)
        row = TrendsQuery.new(period: "7d").comparison.first
        assert_nil row[:delta_pct]
      end

      test "comparison sorts by current_cost DESC" do
        build_event(name: "Cheap",   finished_at: 1.day.ago, estimated_cost: 1.0)
        build_event(name: "Premium", finished_at: 1.day.ago, estimated_cost: 10.0)
        build_event(name: "Mid",     finished_at: 1.day.ago, estimated_cost: 5.0)

        names = TrendsQuery.new(period: "7d").comparison.map { |r| r[:name] }
        assert_equal %w[Premium Mid Cheap], names
      end

      test "comparison includes workloads that only appear in previous period" do
        build_event(name: "Deprecated", finished_at: 8.days.ago, estimated_cost: 2.0)
        rows = TrendsQuery.new(period: "7d").comparison
        assert_equal 1, rows.size
        assert_equal "Deprecated",   rows[0][:name]
        assert_in_delta 0.0,          rows[0][:current_cost]
        assert_in_delta 2.0,          rows[0][:previous_cost]
      end

      test "comparison respects event_type filter" do
        build_event(name: "X", event_type: "request", finished_at: 1.day.ago, estimated_cost: 1.0)
        build_event(name: "X", event_type: "job",     finished_at: 1.day.ago, estimated_cost: 9.0)

        rows = TrendsQuery.new(period: "7d", event_type: "job").comparison
        assert_equal 1, rows.size
        assert_in_delta 9.0, rows[0][:current_cost]
      end

      test "comparison caps results at COMPARISON_LIMIT, keeping most expensive" do
        (TrendsQuery::COMPARISON_LIMIT + 5).times do |i|
          build_event(name: "W#{i}", finished_at: 1.day.ago, estimated_cost: i.to_f)
        end

        rows = TrendsQuery.new(period: "7d").comparison
        assert_equal TrendsQuery::COMPARISON_LIMIT, rows.size
        # Highest cost first; the bottom 5 (i=0..4) are dropped.
        assert_operator rows.last[:current_cost], :>=, 5.0
      end

      test "comparison limit can be overridden" do
        10.times { |i| build_event(name: "W#{i}", finished_at: 1.day.ago, estimated_cost: i.to_f) }

        rows = TrendsQuery.new(period: "7d").comparison(limit: 3)
        assert_equal 3, rows.size
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
    end
  end
end

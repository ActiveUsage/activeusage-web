module ActiveUsage
  module Web
    # Period-over-period analytics for the trends page: time-bucketed cost chart
    # and workload comparison between current and previous period.
    class TrendsQuery
      include QueryFiltering

      DEFAULT_PERIOD    = "30d"
      COMPARISON_LIMIT  = 50

      attr_reader :period, :event_type

      def initialize(period: DEFAULT_PERIOD, event_type: "all")
        @period     = normalize_range(period, default: DEFAULT_PERIOD)
        @event_type = normalize_event_type(event_type)
      end

      def chart_data
        case @period
        when "1h"  then ruby_time_buckets(bucket_seconds: 300,   count: 12) { |t| t.strftime("%H:%M") }
        when "24h" then ruby_time_buckets(bucket_seconds: 3_600, count: 24) { |t| t.strftime("%H:00") }
        when "7d", "30d" then sql_date_buckets { |d| d.strftime("%-d %b") }
        end
      end

      def comparison(limit: COMPARISON_LIMIT)
        current  = aggregate_by_workload(current_scope)
        previous = aggregate_by_workload(previous_scope)

        (current.keys + previous.keys).uniq.map do |name|
          build_comparison_row(name, current[name], previous[name])
        end.sort_by { |r| -r[:current_cost] }.first(limit)
      end

      def current_period_start
        @current_period_start ||= period_seconds.seconds.ago
      end

      def previous_period_start
        @previous_period_start ||= (period_seconds * 2).seconds.ago
      end

      private

      def ruby_time_buckets(bucket_seconds:, count:, &label_fn)
        now     = Time.now
        buckets = Array.new(count) do |i|
          start_time = now - ((count - i) * bucket_seconds)
          { label: label_fn.call(start_time), total_cost: 0.0, events_count: 0, prev_total_cost: 0.0, prev_events_count: 0 }
        end

        fill_buckets(buckets, current_scope, now, bucket_seconds, count, :total_cost, :events_count, time_shift: 0)
        fill_buckets(buckets, previous_scope, now, bucket_seconds, count, :prev_total_cost, :prev_events_count, time_shift: period_seconds)

        buckets.each do |b|
          b[:total_cost]      = b[:total_cost].round(10)
          b[:prev_total_cost] = b[:prev_total_cost].round(10)
        end
      end

      def fill_buckets(buckets, scope, now, bucket_seconds, count, cost_key, count_key, time_shift:)
        scope.select(:finished_at, :estimated_cost).each do |event|
          idx = count - 1 - ((now - event.finished_at - time_shift) / bucket_seconds).floor.to_i
          next unless idx >= 0 && idx < count
          buckets[idx][cost_key]  += event.estimated_cost.to_f
          buckets[idx][count_key] += 1
        end
      end

      def sql_date_buckets(&label_fn)
        current_rows = group_by_date(current_scope)
        prev_rows    = group_by_date(previous_scope).transform_keys { |d| d + period_days.days }

        (current_period_start.to_date..Date.today).map do |date|
          cur  = current_rows[date] || { total_cost: 0.0, events_count: 0 }
          prev = prev_rows[date]    || { total_cost: 0.0, events_count: 0 }
          {
            label:             label_fn.call(date),
            total_cost:        cur[:total_cost].round(10),
            events_count:      cur[:events_count],
            prev_total_cost:   prev[:total_cost].round(10),
            prev_events_count: prev[:events_count]
          }
        end
      end

      def group_by_date(scope)
        scope
          .group("DATE(finished_at)")
          .select("DATE(finished_at) AS day, SUM(estimated_cost) AS total_cost, COUNT(*) AS events_count")
          .each_with_object({}) do |r, h|
            h[r[:day].to_date] = { total_cost: r[:total_cost].to_f, events_count: r[:events_count].to_i }
          end
      end

      def aggregate_by_workload(scope)
        scope
          .group(:name)
          .select("name, MIN(event_type) AS event_type, SUM(estimated_cost) AS total_cost, COUNT(*) AS events_count")
          .each_with_object({}) do |r, h|
            h[r.name] = {
              event_type:   r[:event_type].to_s,
              total_cost:   r[:total_cost].to_f,
              events_count: r[:events_count].to_i
            }
          end
      end

      def build_comparison_row(name, current, previous)
        cur  = current  || { event_type: "", total_cost: 0.0, events_count: 0 }
        prev = previous || { event_type: "", total_cost: 0.0, events_count: 0 }
        {
          name:           name,
          event_type:     (cur[:event_type].presence || prev[:event_type]).to_s,
          current_cost:   cur[:total_cost].round(10),
          previous_cost:  prev[:total_cost].round(10),
          current_count:  cur[:events_count],
          previous_count: prev[:events_count],
          delta_pct:      compute_delta(cur[:total_cost], prev[:total_cost])
        }
      end

      def compute_delta(current_cost, previous_cost)
        return nil unless previous_cost.positive?
        ((current_cost - previous_cost) / previous_cost * 100).round(1)
      end

      def current_scope
        filter_event_type(Event.where("finished_at >= ?", current_period_start), @event_type)
      end

      def previous_scope
        filter_event_type(
          Event.where("finished_at >= ? AND finished_at < ?", previous_period_start, current_period_start),
          @event_type
        )
      end

      def period_seconds
        range_seconds(@period)
      end

      def period_days
        period_seconds / 86_400
      end
    end
  end
end

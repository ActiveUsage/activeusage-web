module ActiveUsage
  module Web
    # Aggregations for the main dashboard pages: summary metrics, top workloads,
    # SQL fingerprint rankings, and paginated event/workload/sql lists.
    # All filtering goes through {QueryFiltering}.
    class DashboardQuery
      include QueryFiltering

      DEFAULT_RANGE = "24h"

      attr_reader :range, :event_type

      def initialize(range: DEFAULT_RANGE, event_type: "all")
        @range      = normalize_range(range, default: DEFAULT_RANGE)
        @event_type = normalize_event_type(event_type)
      end

      def summary
        s = event_scope
        {
          events_count:         s.count,
          total_estimated_cost: s.sum(:estimated_cost).to_f,
          last_event_at:        s.maximum(:finished_at)
        }
      end

      def top_workloads(limit: 5)
        workload_rows.first(limit)
      end

      def all_workloads
        workload_rows
      end

      def top_sql_queries(limit: 5)
        sql_query_rows.first(limit)
      end

      def all_sql_queries
        sql_query_rows
      end

      def events_count
        event_scope.count
      end

      def all_events(page: 1, per_page: Paginator::PER_PAGE)
        event_scope.order(finished_at: :desc)
                   .offset((page - 1) * per_page)
                   .limit(per_page)
      end

      private

      def event_scope
        filter_event_type(Event.where("finished_at >= ?", cutoff), @event_type)
      end

      def sql_scope
        filter_event_type(SqlQuery.where("finished_at >= ?", cutoff), @event_type)
      end

      def cutoff
        Time.now - range_seconds(@range)
      end

      def workload_rows
        event_scope
          .group(:name)
          .select("name, MIN(event_type) AS event_type, SUM(estimated_cost) AS total_cost, COUNT(*) AS events_count, MAX(finished_at) AS last_seen_at")
          .order("total_cost DESC")
          .map do |r|
            {
              name:         r.name,
              event_type:   r[:event_type].to_s,
              total_cost:   r[:total_cost].to_f,
              events_count: r[:events_count].to_i,
              last_seen_at: r[:last_seen_at]
            }
          end
      end

      def sql_query_rows
        sql_scope
          .group(:fingerprint)
          .select(
            "fingerprint",
            "SUM(db_cost) AS total_db_cost",
            "SUM(duration_ms) AS total_duration_ms",
            "SUM(calls) AS total_calls",
            "COUNT(*) AS events_count",
            "MAX(finished_at) AS last_seen_at"
          )
          .order("total_db_cost DESC")
          .map do |r|
            fingerprint = SqlFingerprint.new(r.fingerprint)
            {
              fingerprint:     fingerprint.to_s,
              query_type:      fingerprint.query_type,
              relation_name:   fingerprint.relation_name,
              db_cost:         r[:total_db_cost].to_f.round(10),
              sql_duration_ms: r[:total_duration_ms].to_f.round(2),
              calls:           r[:total_calls].to_i,
              events_count:    r[:events_count].to_i,
              last_seen_at:    r[:last_seen_at]
            }
          end
      end
    end
  end
end

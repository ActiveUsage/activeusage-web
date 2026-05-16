module ActiveUsage
  module Web
    # Bridges between ActiveUsage's instrumentation Store and our two-table schema.
    # On each flush, builds rows for activeusage_events and activeusage_sql_queries
    # and inserts them in two batches.
    class ActiveRecordAdapter
      def record(events)
        events = Array(events)
        return if events.empty?

        calculator     = CostCalculator.from_cost_rate
        now            = Time.current
        event_rows     = events.map { |e| build_event_row(e, calculator, now) }
        sql_query_rows = events.flat_map { |e| build_sql_query_rows(e, calculator, now) }

        insert_events(event_rows)
        insert_sql_queries(sql_query_rows)
      end

      def clear!; end
      def shutdown!; end

      private

      def insert_events(rows)
        Event.insert_all(rows)
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
        log_error("Failed to insert event rows", e)
      end

      def insert_sql_queries(rows)
        return if rows.empty?

        SqlQuery.insert_all(rows)
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
        log_error("Failed to insert SQL query rows", e)
      end

      def build_event_row(event, calculator, now)
        sql_queries     = normalize_sql_queries(event.sql_queries)
        duration_ms     = compute_duration_ms(event)
        sql_duration_ms = sum_sql_duration(sql_queries)
        sql_calls       = sum_sql_calls(sql_queries)
        compute_cost, db_cost = calculator.estimate(duration_ms: duration_ms, sql_duration_ms: sql_duration_ms)

        {
          event_type:        event.type.to_s,
          name:              event.name.to_s,
          started_at:        event.started_at,
          finished_at:       event.finished_at,
          duration_ms:       duration_ms,
          sql_duration_ms:   sql_duration_ms.round(3),
          sql_calls:         sql_calls,
          allocations:       event.allocations.to_i,
          external_calls:    0,
          retry_count:       event.retry_count.to_i,
          tags:              event.tags || {},
          estimated_cost:    (compute_cost + db_cost).round(10),
          cost_breakdown:    { compute: compute_cost.round(10), db: db_cost.round(10) },
          window_started_at: event.window_started_at,
          created_at:        now,
          updated_at:        now
        }
      end

      def build_sql_query_rows(event, calculator, now)
        sql_queries = normalize_sql_queries(event.sql_queries)
        return [] if sql_queries.empty?

        sql_duration_ms = sum_sql_duration(sql_queries)
        _, db_cost      = calculator.estimate(duration_ms: compute_duration_ms(event), sql_duration_ms: sql_duration_ms)

        sql_queries.filter_map do |q|
          next if q[:fingerprint].to_s.empty?

          q_db_cost = sql_duration_ms.positive? ? (db_cost * q[:total_duration_ms] / sql_duration_ms) : 0.0

          {
            fingerprint:       q[:fingerprint].to_s,
            adapter_name:      q[:adapter_name].to_s,
            duration_ms:       q[:total_duration_ms],
            calls:             q[:calls],
            db_cost:           q_db_cost.round(10),
            event_name:        event.name.to_s,
            event_type:        event.type.to_s,
            finished_at:       event.finished_at,
            window_started_at: event.window_started_at,
            created_at:        now,
            updated_at:        now
          }
        end
      end

      # Normalizes once: accept hashes with symbol or string keys, return symbol-keyed
      # with already-coerced numeric types so callers don't repeat the dance.
      def normalize_sql_queries(sql_queries)
        Array(sql_queries).map do |q|
          {
            fingerprint:       (q[:fingerprint]       || q["fingerprint"]),
            total_duration_ms: (q[:total_duration_ms] || q["total_duration_ms"]).to_f,
            calls:             (q[:calls]             || q["calls"]).to_i,
            adapter_name:      (q[:adapter_name]      || q["adapter_name"])
          }
        end
      end

      def sum_sql_duration(sql_queries)
        sql_queries.sum { |q| q[:total_duration_ms] }
      end

      def sum_sql_calls(sql_queries)
        sql_queries.sum { |q| q[:calls] }
      end

      def compute_duration_ms(event)
        return 0.0 unless event.started_at && event.finished_at

        ((event.finished_at - event.started_at) * 1000.0).round(3)
      end

      def log_error(message, error)
        ActiveUsage.logger.error("[ActiveUsage::Web] #{message}: #{error.message}")
      end
    end
  end
end

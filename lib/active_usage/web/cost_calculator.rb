module ActiveUsage
  module Web
    # Computes compute and DB cost estimates for events based on the current CostRate.
    # CostRate is looked up once at construction time so a single calculator can be
    # reused for an entire batch of events without re-querying the DB.
    class CostCalculator
      MS_PER_HOUR = 3_600_000.0

      attr_reader :compute_per_hour, :db_per_hour

      @missing_rate_warned = false

      class << self
        attr_accessor :missing_rate_warned

        def from_cost_rate(rate = CostRate.current)
          warn_missing_rate unless rate
          new(
            compute_per_hour: rate&.compute_cost_per_hour.to_f,
            db_per_hour:      rate&.database_cost_per_hour.to_f
          )
        end

        private

        def warn_missing_rate
          return if missing_rate_warned
          ActiveUsage.logger.warn(
            "[ActiveUsage::Web] No CostRate record found. " \
            "Event costs will be recorded as $0 until you set compute_cost_per_hour and database_cost_per_hour. " \
            "Visit /your_engine_mount/cost_rates/new in your app."
          )
          self.missing_rate_warned = true
        end
      end

      def initialize(compute_per_hour:, db_per_hour:)
        @compute_per_hour = compute_per_hour.to_f
        @db_per_hour      = db_per_hour.to_f
      end

      def estimate(duration_ms:, sql_duration_ms:)
        compute = duration_ms.to_f     / MS_PER_HOUR * compute_per_hour
        db      = sql_duration_ms.to_f / MS_PER_HOUR * db_per_hour
        [ compute, db ]
      end
    end
  end
end

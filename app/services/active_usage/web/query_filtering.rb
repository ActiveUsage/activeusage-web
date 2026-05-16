module ActiveUsage
  module Web
    # Shared range/event_type validation and filtering helpers for query services.
    module QueryFiltering
      TIME_RANGES = {
        "1h"  => 3_600,
        "24h" => 86_400,
        "7d"  => 604_800,
        "30d" => 2_592_000
      }.freeze

      EVENT_TYPES = %w[all request job task].freeze

      private

      def normalize_range(value, default:)
        TIME_RANGES.key?(value.to_s) ? value.to_s : default
      end

      def normalize_event_type(value, default: "all")
        EVENT_TYPES.include?(value.to_s) ? value.to_s : default
      end

      def range_seconds(key)
        TIME_RANGES.fetch(key)
      end

      def filter_event_type(scope, event_type)
        event_type == "all" ? scope : scope.where(event_type: event_type)
      end
    end
  end
end

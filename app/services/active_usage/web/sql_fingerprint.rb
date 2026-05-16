module ActiveUsage
  module Web
    # Value object wrapping a SQL fingerprint string with parsing helpers.
    # Extracts the query type (SELECT/UPDATE/...) and primary relation name (table)
    # from a normalized SQL fingerprint.
    class SqlFingerprint
      RELATION_PATTERNS = [
        /\bFROM\s+"?([a-zA-Z0-9_.]+)"?/i,
        /\bJOIN\s+"?([a-zA-Z0-9_.]+)"?/i,
        /\bUPDATE\s+"?([a-zA-Z0-9_.]+)"?/i,
        /\bINTO\s+"?([a-zA-Z0-9_.]+)"?/i,
        /\bDELETE\s+FROM\s+"?([a-zA-Z0-9_.]+)"?/i
      ].freeze

      attr_reader :raw

      def initialize(raw)
        @raw = raw.to_s
      end

      def query_type
        raw[/\A([A-Z]+)/, 1] || "UNKNOWN"
      end

      def relation_name
        RELATION_PATTERNS.each do |pattern|
          match = raw.match(pattern)
          return match[1] if match
        end
        nil
      end

      def to_s
        raw
      end
    end
  end
end

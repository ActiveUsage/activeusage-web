module ActiveUsage
  module Web
    class ApplicationController < ActionController::Base
      TIME_RANGES = %w[1h 24h 7d 30d].freeze
      EVENT_TYPES = %w[all request job task].freeze

      protect_from_forgery with: :exception

      http_basic_authenticate_with(
        name: "activeusage",
        password: ENV.fetch("ACTIVEUSAGE_PASSWORD") { Rails.application.credentials.active_usage.password }
      )

      private

      def set_dashboard_filters
        @range      = valid_range
        @event_type = valid_event_type
      end

      def valid_range
        TIME_RANGES.include?(params[:range].to_s) ? params[:range].to_s : "24h"
      end

      def valid_event_type
        EVENT_TYPES.include?(params[:event_type].to_s) ? params[:event_type].to_s : "all"
      end

      def valid_period
        TIME_RANGES.include?(params[:period].to_s) ? params[:period].to_s : "30d"
      end

      def dashboard_query
        @dashboard_query ||= DashboardQuery.new(range: @range, event_type: @event_type)
      end
    end
  end
end

module ActiveUsage
  module Web
    class TrendsController < ApplicationController
      def index
        @period     = valid_period
        @event_type = valid_event_type

        q = TrendsQuery.new(period: @period, event_type: @event_type)

        @chart_data            = q.chart_data
        @comparison            = q.comparison
        @current_period_start  = q.current_period_start
        @previous_period_start = q.previous_period_start
      end
    end
  end
end

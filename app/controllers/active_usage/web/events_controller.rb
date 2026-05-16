module ActiveUsage
  module Web
    class EventsController < ApplicationController
      before_action :set_dashboard_filters

      def index
        @paginator = Paginator.new(total_count: dashboard_query.events_count, page: params[:page])
        @events    = dashboard_query.all_events(page: @paginator.page, per_page: @paginator.per_page)
      end
    end
  end
end

module ActiveUsage
  module Web
    class WorkloadsController < ApplicationController
      before_action :set_dashboard_filters

      def index
        all        = dashboard_query.all_workloads
        @paginator = Paginator.new(total_count: all.size, page: params[:page])
        @workloads = @paginator.slice(all)
      end
    end
  end
end

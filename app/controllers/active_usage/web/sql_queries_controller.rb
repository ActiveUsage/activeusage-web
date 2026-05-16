module ActiveUsage
  module Web
    class SqlQueriesController < ApplicationController
      before_action :set_dashboard_filters

      def index
        all          = dashboard_query.all_sql_queries
        @paginator   = Paginator.new(total_count: all.size, page: params[:page])
        @sql_queries = @paginator.slice(all)
      end
    end
  end
end

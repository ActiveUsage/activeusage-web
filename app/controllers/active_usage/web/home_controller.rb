module ActiveUsage
  module Web
    class HomeController < ApplicationController
      before_action :set_dashboard_filters

      def index
        @summary         = dashboard_query.summary
        @top_workloads   = dashboard_query.top_workloads(limit: 5)
        @top_sql_queries = dashboard_query.top_sql_queries(limit: 5)
      end
    end
  end
end

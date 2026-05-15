module ActiveUsage
  module Web
    class ConfigurationsController < ApplicationController
      def index
        @configurations = Configuration.order(created_at: :desc)
      end

      def new
        @configuration = Configuration.new
      end

      def create
        @configuration = Configuration.new(configuration_params)

        if @configuration.save
          redirect_to configurations_path
        else
          render :new, status: :unprocessable_content
        end
      end

      private

      def configuration_params
        params.expect(configuration: [ :compute_cost_per_hour, :database_cost_per_hour ])
      end
    end
  end
end

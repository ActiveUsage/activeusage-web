module ActiveUsage
  module Web
    class CostRatesController < ApplicationController
      def index
        @cost_rates = CostRate.order(created_at: :desc)
      end

      def new
        @cost_rate = CostRate.new
      end

      def create
        @cost_rate = CostRate.new(cost_rate_params)

        if @cost_rate.save
          redirect_to cost_rates_path
        else
          render :new, status: :unprocessable_content
        end
      end

      private

      def cost_rate_params
        params.expect(cost_rate: [ :compute_cost_per_hour, :database_cost_per_hour ])
      end
    end
  end
end

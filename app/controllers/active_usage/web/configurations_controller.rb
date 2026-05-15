module ActiveUsage
  module Web
    class ConfigurationsController < ApplicationController
      before_action :set_configuration, only: %i[ show edit update destroy ]

      # GET /configurations
      def index
        @configurations = Configuration.all
      end

      # GET /configurations/1
      def show
      end

      # GET /configurations/new
      def new
        @configuration = Configuration.new
      end

      # GET /configurations/1/edit
      def edit
      end

      # POST /configurations
      def create
        @configuration = Configuration.new(configuration_params)

        if @configuration.save
          redirect_to @configuration, notice: "Configuration was successfully created."
        else
          render :new, status: :unprocessable_content
        end
      end

      # PATCH/PUT /configurations/1
      def update
        if @configuration.update(configuration_params)
          redirect_to @configuration, notice: "Configuration was successfully updated.", status: :see_other
        else
          render :edit, status: :unprocessable_content
        end
      end

      # DELETE /configurations/1
      def destroy
        @configuration.destroy!
        redirect_to configurations_path, notice: "Configuration was successfully destroyed.", status: :see_other
      end

      private
      # Use callbacks to share common setup or constraints between actions.
      def set_configuration
        @configuration = Configuration.find(params.expect(:id))
      end

      # Only allow a list of trusted parameters through.
      def configuration_params
        params.expect(configuration: [ :compute_cost_per_hour, :database_cost_per_hour ])
      end
    end
  end
end

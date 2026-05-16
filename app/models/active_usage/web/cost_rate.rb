module ActiveUsage
  module Web
    class CostRate < ApplicationRecord
      validates :compute_cost_per_hour,  presence: true, numericality: { greater_than: 0 }
      validates :database_cost_per_hour, presence: true, numericality: { greater_than: 0 }

      def self.current
        order(created_at: :desc).first
      end
    end
  end
end

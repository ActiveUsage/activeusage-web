module ActiveUsage
  module Web
    class Configuration < ApplicationRecord
      validates :compute_cost_per_hour, presence: true,
                                        numericality: { greater_than: 0 }
      validates :database_cost_per_hour, presence: true,
                                         numericality: { greater_than: 0 }
    end
  end
end

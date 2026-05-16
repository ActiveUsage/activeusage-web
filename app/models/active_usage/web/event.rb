module ActiveUsage
  module Web
    class Event < ApplicationRecord
      scope :recent_first, -> { order(finished_at: :desc) }
    end
  end
end

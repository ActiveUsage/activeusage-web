require "test_helper"

module ActiveUsage
  module Web
    class CostRateTest < ActiveSupport::TestCase
      setup { CostRate.delete_all }

      test "valid with positive rates" do
        rate = CostRate.new(compute_cost_per_hour: 1.0, database_cost_per_hour: 2.0)
        assert rate.valid?
      end

      test "invalid without compute_cost_per_hour (DB default 0 fails numericality)" do
        rate = CostRate.new(database_cost_per_hour: 2.0)
        refute rate.valid?
        assert rate.errors[:compute_cost_per_hour].any?
      end

      test "invalid with zero compute_cost_per_hour" do
        rate = CostRate.new(compute_cost_per_hour: 0, database_cost_per_hour: 1.0)
        refute rate.valid?
        assert rate.errors[:compute_cost_per_hour].any?
      end

      test "invalid with negative compute_cost_per_hour" do
        rate = CostRate.new(compute_cost_per_hour: -1.0, database_cost_per_hour: 1.0)
        refute rate.valid?
      end

      test "invalid without database_cost_per_hour (DB default 0 fails numericality)" do
        rate = CostRate.new(compute_cost_per_hour: 1.0)
        refute rate.valid?
        assert rate.errors[:database_cost_per_hour].any?
      end

      test "invalid with zero database_cost_per_hour" do
        rate = CostRate.new(compute_cost_per_hour: 1.0, database_cost_per_hour: 0)
        refute rate.valid?
      end

      test "invalid with negative database_cost_per_hour" do
        rate = CostRate.new(compute_cost_per_hour: 1.0, database_cost_per_hour: -2.5)
        refute rate.valid?
      end

      test ".current returns the most recently created record" do
        older = CostRate.create!(compute_cost_per_hour: 1.0, database_cost_per_hour: 2.0, created_at: 2.hours.ago)
        newer = CostRate.create!(compute_cost_per_hour: 3.0, database_cost_per_hour: 4.0, created_at: 1.hour.ago)
        assert_equal newer, CostRate.current
      end

      test ".current returns nil when no records exist" do
        assert_nil CostRate.current
      end
    end
  end
end

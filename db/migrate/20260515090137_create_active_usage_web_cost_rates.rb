class CreateActiveUsageWebCostRates < ActiveRecord::Migration[8.1]
  def change
    create_table :active_usage_web_cost_rates do |t|
      t.decimal :compute_cost_per_hour, null: false, precision: 12, scale: 4, default: 0
      t.decimal :database_cost_per_hour, null: false, precision: 12, scale: 4, default: 0

      t.timestamps null: false
    end
  end
end

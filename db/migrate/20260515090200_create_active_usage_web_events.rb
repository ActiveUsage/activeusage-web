class CreateActiveUsageWebEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :active_usage_web_events do |t|
      t.string   :event_type,      null: false
      t.string   :name,            null: false
      t.datetime :started_at,      null: false
      t.datetime :finished_at,     null: false
      t.float    :duration_ms,     null: false, default: 0.0
      t.float    :sql_duration_ms, null: false, default: 0.0
      t.integer  :sql_calls,       null: false, default: 0
      t.integer  :allocations,     null: false, default: 0
      t.integer  :external_calls,  null: false, default: 0
      t.integer  :retry_count,     null: false, default: 0
      t.float    :cpu_time_ms
      t.bigint   :memory_bytes
      t.json     :tags,            null: false, default: {}
      t.decimal  :estimated_cost,  null: false, precision: 16, scale: 10, default: 0
      t.json     :cost_breakdown,  null: false, default: {}
      t.datetime :window_started_at, null: false

      t.timestamps
    end

    add_index :active_usage_web_events, :event_type
    add_index :active_usage_web_events, :name
    add_index :active_usage_web_events, :finished_at
    add_index :active_usage_web_events, :window_started_at
    add_index :active_usage_web_events, [ :event_type, :finished_at ]
    add_index :active_usage_web_events, [ :name, :finished_at ]
  end
end

class CreateActiveUsageWebSqlQueries < ActiveRecord::Migration[7.2]
  def change
    create_table :active_usage_web_sql_queries do |t|
      t.string   :fingerprint,       null: false
      t.string   :adapter_name
      t.float    :duration_ms,       null: false, default: 0.0
      t.integer  :calls,             null: false, default: 1
      t.decimal  :db_cost,           null: false, precision: 16, scale: 10, default: 0
      t.string   :event_name,        null: false
      t.string   :event_type,        null: false
      t.datetime :finished_at,       null: false
      t.datetime :window_started_at, null: false

      t.timestamps
    end

    add_index :active_usage_web_sql_queries, :fingerprint
    add_index :active_usage_web_sql_queries, :finished_at
    add_index :active_usage_web_sql_queries, :event_name
    add_index :active_usage_web_sql_queries, :event_type
    add_index :active_usage_web_sql_queries, [ :event_type, :finished_at ]
    add_index :active_usage_web_sql_queries, [ :fingerprint, :finished_at ]
  end
end

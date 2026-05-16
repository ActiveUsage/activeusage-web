# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_15_090202) do
  create_table "active_usage_web_cost_rates", force: :cascade do |t|
    t.decimal "compute_cost_per_hour", precision: 12, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "database_cost_per_hour", precision: 12, scale: 4, default: "0.0", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_usage_web_events", force: :cascade do |t|
    t.integer "allocations", default: 0, null: false
    t.json "cost_breakdown", default: {}, null: false
    t.float "cpu_time_ms"
    t.datetime "created_at", null: false
    t.float "duration_ms", default: 0.0, null: false
    t.decimal "estimated_cost", precision: 16, scale: 10, default: "0.0", null: false
    t.string "event_type", null: false
    t.integer "external_calls", default: 0, null: false
    t.datetime "finished_at", null: false
    t.bigint "memory_bytes"
    t.string "name", null: false
    t.integer "retry_count", default: 0, null: false
    t.integer "sql_calls", default: 0, null: false
    t.float "sql_duration_ms", default: 0.0, null: false
    t.datetime "started_at", null: false
    t.json "tags", default: {}, null: false
    t.datetime "updated_at", null: false
    t.datetime "window_started_at", null: false
    t.index ["event_type", "finished_at"], name: "index_active_usage_web_events_on_event_type_and_finished_at"
    t.index ["event_type"], name: "index_active_usage_web_events_on_event_type"
    t.index ["finished_at"], name: "index_active_usage_web_events_on_finished_at"
    t.index ["name", "finished_at"], name: "index_active_usage_web_events_on_name_and_finished_at"
    t.index ["name"], name: "index_active_usage_web_events_on_name"
    t.index ["window_started_at"], name: "index_active_usage_web_events_on_window_started_at"
  end

  create_table "active_usage_web_sql_queries", force: :cascade do |t|
    t.string "adapter_name"
    t.integer "calls", default: 1, null: false
    t.datetime "created_at", null: false
    t.decimal "db_cost", precision: 16, scale: 10, default: "0.0", null: false
    t.float "duration_ms", default: 0.0, null: false
    t.string "event_name", null: false
    t.string "event_type", null: false
    t.string "fingerprint", null: false
    t.datetime "finished_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "window_started_at", null: false
    t.index ["event_name"], name: "index_active_usage_web_sql_queries_on_event_name"
    t.index ["event_type", "finished_at"], name: "idx_on_event_type_finished_at_e6ec783fbf"
    t.index ["event_type"], name: "index_active_usage_web_sql_queries_on_event_type"
    t.index ["fingerprint", "finished_at"], name: "idx_on_fingerprint_finished_at_d0bc743336"
    t.index ["fingerprint"], name: "index_active_usage_web_sql_queries_on_fingerprint"
    t.index ["finished_at"], name: "index_active_usage_web_sql_queries_on_finished_at"
  end
end

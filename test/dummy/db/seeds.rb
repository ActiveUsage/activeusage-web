# Populates Event, SqlQuery, and CostRate with realistic data spanning the last
# 60 days so every dashboard time range (1h / 24h / 7d / 30d) has data, and the
# trends page has both current AND previous periods to compare against.
#
# Run with:
#   bin/rails db:seed
#
# Wipes existing data before generating new rows.

require "active_usage/web"

Event    = ActiveUsage::Web::Event
SqlQuery = ActiveUsage::Web::SqlQuery
CostRate = ActiveUsage::Web::CostRate

puts "[seed] Wiping existing data…"
Event.delete_all
SqlQuery.delete_all
CostRate.delete_all

puts "[seed] Creating CostRate ($0.10 compute / $0.25 db per hour)…"
CostRate.create!(compute_cost_per_hour: 0.10, database_cost_per_hour: 0.25)

# ─── Domain ─────────────────────────────────────────────────────────────────

REQUESTS = %w[
  PostsController#index
  PostsController#show
  PostsController#create
  PostsController#update
  UsersController#index
  UsersController#show
  UsersController#update
  DashboardController#index
  ApiController#search
  SessionsController#create
  OrdersController#index
  OrdersController#create
  CommentsController#create
  ProductsController#index
].freeze

JOBS = %w[
  MailerJob
  ReportGenerationJob
  DataCleanupJob
  ExportJob
  ImportJob
  NotificationJob
  WelcomeEmailJob
  IndexingJob
].freeze

TASKS = %w[
  stats:refresh
  users:cleanup
  analytics:rollup
  sitemap:generate
].freeze

SQL_FINGERPRINTS = [
  "SELECT * FROM users WHERE id = ?",
  "SELECT * FROM posts WHERE author_id = ? LIMIT ?",
  "SELECT COUNT(*) FROM orders WHERE created_at >= ?",
  "UPDATE users SET last_seen_at = ? WHERE id = ?",
  "INSERT INTO sessions (user_id, token) VALUES (?, ?)",
  "SELECT products.*, categories.name FROM products JOIN categories ON categories.id = products.category_id WHERE products.published = ?",
  "DELETE FROM expired_sessions WHERE created_at < ?",
  "SELECT posts.* FROM posts JOIN comments ON comments.post_id = posts.id WHERE comments.user_id = ?",
  "SELECT * FROM api_keys WHERE token = ?",
  "SELECT * FROM orders WHERE user_id = ? AND status = ? ORDER BY created_at DESC",
  "UPDATE inventory SET quantity = quantity - ? WHERE product_id = ?",
  "INSERT INTO audit_logs (user_id, action, payload) VALUES (?, ?, ?)"
].freeze

# ─── Generation parameters ──────────────────────────────────────────────────

TOTAL_EVENTS  = 2_000
DAYS_BACK     = 60
WINDOW_SIZE_S = 300
COMPUTE_RATE  = 0.10
DB_RATE       = 0.25

rng = Random.new(42)

# Weighted random within a range
def sample_days_ago(rng)
  weight = rng.rand
  case weight
  when 0.0...0.25 then rng.rand(0.0..1.0)        # last 24h: 25%
  when 0.25...0.55 then rng.rand(1.0..7.0)       # 1–7d:     30%
  when 0.55...0.80 then rng.rand(7.0..14.0)      # 7–14d:    25%
  else rng.rand(14.0..DAYS_BACK.to_f)            # 14–60d:   20%
  end
end

def sample_workload(rng)
  case rng.rand
  when 0.0...0.70 then [ "request", REQUESTS.sample(random: rng) ]
  when 0.70...0.95 then [ "job",     JOBS.sample(random: rng) ]
  else                  [ "task",    TASKS.sample(random: rng) ]
  end
end

def sample_duration(rng, event_type)
  case event_type
  when "request" then rng.rand(15.0..500.0)
  when "job"     then rng.rand(100.0..5_000.0)
  when "task"    then rng.rand(500.0..30_000.0)
  end
end

# ─── Build rows ─────────────────────────────────────────────────────────────

puts "[seed] Generating #{TOTAL_EVENTS} events across the last #{DAYS_BACK} days…"

event_rows = []
sql_query_rows = []

TOTAL_EVENTS.times do
  finished_at = Time.now - sample_days_ago(rng).days

  event_type, name = sample_workload(rng)
  duration_ms      = sample_duration(rng, event_type)

  num_sql      = rng.rand(0..5)
  sql_picks    = Array.new(num_sql) { { fp: SQL_FINGERPRINTS.sample(random: rng), duration: rng.rand(0.5..50.0) } }
  total_sql_ms = sql_picks.sum { |s| s[:duration] }

  compute_cost = (duration_ms  / 3_600_000.0 * COMPUTE_RATE).round(10)
  db_cost      = (total_sql_ms / 3_600_000.0 * DB_RATE).round(10)

  window_started_at = Time.at((finished_at.to_i / WINDOW_SIZE_S) * WINDOW_SIZE_S)

  event_rows << {
    event_type:        event_type,
    name:              name,
    started_at:        finished_at - (duration_ms / 1000.0),
    finished_at:       finished_at,
    duration_ms:       duration_ms.round(3),
    sql_duration_ms:   total_sql_ms.round(3),
    sql_calls:         num_sql,
    allocations:       rng.rand(500..80_000),
    external_calls:    0,
    retry_count:       0,
    tags:              { env: "development" },
    estimated_cost:    (compute_cost + db_cost).round(10),
    cost_breakdown:    { compute: compute_cost, db: db_cost },
    window_started_at: window_started_at,
    created_at:        finished_at,
    updated_at:        finished_at
  }

  sql_picks.each do |pick|
    q_db_cost = (total_sql_ms.positive? ? db_cost * pick[:duration] / total_sql_ms : 0.0).round(10)
    sql_query_rows << {
      fingerprint:       pick[:fp],
      adapter_name:      "SQLite",
      duration_ms:       pick[:duration].round(3),
      calls:             1,
      db_cost:           q_db_cost,
      event_name:        name,
      event_type:        event_type,
      finished_at:       finished_at,
      window_started_at: window_started_at,
      created_at:        finished_at,
      updated_at:        finished_at
    }
  end
end

# ─── Insert in batches ──────────────────────────────────────────────────────

puts "[seed] Inserting #{event_rows.size} events and #{sql_query_rows.size} sql queries…"

event_rows.each_slice(500)     { |batch| Event.insert_all(batch) }
sql_query_rows.each_slice(500) { |batch| SqlQuery.insert_all(batch) }

puts "[seed] Done."
puts "[seed]   Events:      #{Event.count}"
puts "[seed]   SqlQueries:  #{SqlQuery.count}"
puts "[seed]   CostRates:   #{CostRate.count}"

# ActiveUsage::Web

A local-first Rails Engine dashboard for [ActiveUsage](https://github.com/ActiveUsage/activeusage) — a cost observability tool that estimates compute and database costs per controller action, background job, and custom task in your Rails app.

`activeusage-web` is the visualization layer: it persists ActiveUsage events to your own database and renders a small dashboard with:

- **Overview** — top workloads and SQL fingerprints by estimated cost
- **Trends** — period-over-period cost chart and workload comparison
- **Workloads** — full ranking of controllers, jobs, and tasks by cost
- **SQL Queries** — aggregated SQL fingerprints with allocated DB cost
- **Events** — paginated raw event stream
- **Cost rates** — versioned hourly rates for compute and database

## Installation

Add to your application's Gemfile:

```ruby
gem "activeusage"
gem "activeusage-web"
```

Then:

```bash
bundle install
bin/rails activeusage_web:install:migrations
bin/rails db:migrate
```

## Setup

### 1. Mount the engine

In `config/routes.rb`:

```ruby
mount ActiveUsage::Web::Engine => "/active_usage"
```

Pick a path that suits your app. Common choices: `/active_usage`, `/cost`, `/internal/active_usage`.

### 2. Wire up the adapter

In an initializer (e.g. `config/initializers/active_usage.rb`):

```ruby
ActiveUsage.configure do |config|
  config.adapter = ActiveUsage::Web::ActiveRecordAdapter.new
end
```

This routes ActiveUsage's event queue into the `active_usage_web_events` and `active_usage_web_sql_queries` tables.

### 3. Configure cost rates

Visit `/active_usage/cost_rates/new` and enter the hourly rates that match your hosting setup, e.g.:

- **Compute**: $0.05 / hour (e.g. average app server cost)
- **Database**: $0.10 / hour (e.g. average DB query time cost)

Until a cost rate exists, events are still recorded but `estimated_cost` is `$0`. ActiveUsage logs a one-time warning when no rate is found.

## Authentication

The dashboard uses HTTP Basic auth with username `activeusage` and password from `ENV["ACTIVEUSAGE_PASSWORD"]` (or Rails credentials `active_usage.password`).

```bash
export ACTIVEUSAGE_PASSWORD="your-strong-password"
```

Because the dashboard exposes cost and SQL data, mount it behind your VPN, IP allowlist, or both — not on the public internet.

Custom authenticators that delegate to your app's auth (Devise, Rodauth, etc.) are on the roadmap.

## How it works

ActiveUsage instruments your Rails app via `ActiveSupport::Notifications` subscribers for `process_action.action_controller`, `perform.active_job`, and `sql.active_record`. Each completed request/job/task produces an event with timing and SQL fingerprint data, which gets queued and flushed in batches by a background worker.

`ActiveUsage::Web::ActiveRecordAdapter` is the bridge: it picks up each batch from the queue, computes cost estimates using the current `CostRate`, and writes two row sets:

- **events** — one row per event with totals
- **sql_queries** — one row per (event, SQL fingerprint) pair with per-query allocation

The dashboard reads from these tables with grouped/aggregated queries. Most pages support a time range filter (1h / 24h / 7d / 30d) and event type filter (all / request / job / task).

## Data retention

The two main tables grow indefinitely. For production use, schedule periodic cleanup, e.g. via a recurring job:

```ruby
# Keep last 90 days
ActiveUsage::Web::Event.where("finished_at < ?", 90.days.ago).delete_all
ActiveUsage::Web::SqlQuery.where("finished_at < ?", 90.days.ago).delete_all
```

A built-in retention task is planned for a future release.

## Development

Clone, install dependencies, prepare the dummy app's DB, and run tests:

```bash
bin/setup
bin/rails db:test:prepare
bin/rails test
```

The dummy app lives in `test/dummy/`. To preview the dashboard during development:

```bash
cd test/dummy
bin/rails server
# then visit http://localhost:3000/active_usage_web
```

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).

# Changelog

All notable changes to this project will be documented in this file. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-16

Initial release.

### Added

- Rails Engine (`ActiveUsage::Web::Engine`) with isolated namespace mounting at any path.
- ActiveRecord adapter (`ActiveUsage::Web::ActiveRecordAdapter`) bridging the ActiveUsage
  instrumentation queue to two persistent tables: `active_usage_web_events` and
  `active_usage_web_sql_queries`.
- Cost estimation via versioned `CostRate` records (hourly compute + database rates).
  `CostCalculator` reads the current rate once per batch and logs a one-time warning if missing.
- Dashboard pages:
  - **Overview** — summary stats, top workloads, top SQL fingerprints
  - **Trends** — time-bucketed cost chart (1h / 24h / 7d / 30d) and period-over-period
    workload comparison (capped at 50 workloads by current cost)
  - **Workloads** — paginated ranking of controllers, jobs, tasks
  - **SQL Queries** — paginated SQL fingerprint aggregations with allocated DB cost
  - **Events** — paginated raw event stream with tag display
  - **Cost rates** — versioned hourly rate management with history
- Shared filter bar (time range + event type) and pagination components.
- HTTP Basic authentication (username `activeusage`, password from
  `ENV["ACTIVEUSAGE_PASSWORD"]` or `Rails.application.credentials.active_usage.password`).
- CSRF protection enabled via `protect_from_forgery with: :exception` on the engine's
  base controller.
- Linear-inspired UI with Rails-red accent, system font stack with Inter preferred,
  dense data layout, sidebar navigation with inline SVG icons.
- Composite indexes on `(event_type, finished_at)`, `(name, finished_at)`,
  `(fingerprint, finished_at)` for efficient filtered range queries on large tables.
- Test suite covering services, adapter, paginator, helpers, controllers (smoke + view
  content assertions), and model validations.

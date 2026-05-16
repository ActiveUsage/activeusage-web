module ActiveUsage
  module Web
    module ApplicationHelper
      include IconHelper

      # True when we should nudge the user to configure cost rates.
      # We suppress the banner on the cost_rates pages themselves so the call to action
      # doesn't shout at the user while they're already filling in the form.
      def show_cost_rates_banner?
        return false if controller_name == "cost_rates"

        CostRate.current.nil?
      rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError
        false
      end

      def money(value)
        v = value.to_f
        return "$0.00" if v == 0.0

        return format("$%.4f", v) if v >= 0.01

        precision = -Math.log10(v).floor + 1
        format("$%.#{precision}f", v)
      end

      def event_type_class(event_type)
        {
          "request" => "au-badge--request",
          "job"     => "au-badge--job",
          "task"    => "au-badge--task"
        }.fetch(event_type.to_s, "au-badge--custom")
      end

      def progress_width(value, max_value, min_percent: 10)
        value     = value.to_f
        max_value = max_value.to_f
        return 0 if value <= 0.0 || max_value <= 0.0

        [ (value / max_value * 100.0).round(1), min_percent ].max
      end

      def human_duration_ms(value)
        ms = value.to_f
        return "0ms" if ms <= 0.0
        return "#{ms.round}ms" if ms < 1000
        return "#{(ms / 1000.0).round(1)}s" if ms < 60_000

        minutes = (ms / 60_000.0).floor
        seconds = ((ms % 60_000.0) / 1000.0).round
        "#{minutes}m #{seconds}s"
      end

      def bar_height_pct(value, max_value)
        return 2 if max_value.to_f <= 0
        [ (value.to_f / max_value.to_f * 100).round(1), 2 ].max
      end

      def trends_chart_subtitle(period, current_period_start)
        case period
        when "1h"  then "Last hour · 5-minute buckets"
        when "24h" then "Last 24 hours · 1-hour buckets"
        when "7d"  then "#{current_period_start.strftime('%-d %b')} – #{Date.today.strftime('%-d %b %Y')}"
        when "30d" then "#{current_period_start.strftime('%-d %b')} – #{Date.today.strftime('%-d %b %Y')}"
        end
      end

      def delta_class(delta)
        return "au-delta--neutral" if delta.nil?
        delta > 0 ? "au-delta--up" : "au-delta--down"
      end

      def delta_label(delta)
        return "—" if delta.nil?
        "#{delta > 0 ? '↑' : '↓'} #{delta.abs}%"
      end

      def event_tags_html(tags)
        return "".html_safe unless tags.is_a?(Hash) && tags.any?

        badges = tags.map do |k, v|
          content_tag(:span, "#{k}: #{v}", class: "au-badge au-badge--tag")
        end
        content_tag(:div, safe_join(badges), class: "au-event-tags")
      end

      def range_label(range)
        {
          "1h"  => "last 1 hour",
          "24h" => "last 24 hours",
          "7d"  => "last 7 days",
          "30d" => "last 30 days"
        }.fetch(range.to_s, range.to_s)
      end
    end
  end
end

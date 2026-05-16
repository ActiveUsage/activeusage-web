require "test_helper"

module ActiveUsage
  module Web
    class ApplicationHelperTest < ActionView::TestCase
      include ActiveUsage::Web::ApplicationHelper

      # money

      test "money formats zero as $0.00" do
        assert_equal "$0.00", money(0)
        assert_equal "$0.00", money(0.0)
        assert_equal "$0.00", money(nil)
      end

      test "money uses 4 decimals for values >= 0.01" do
        assert_equal "$0.0100", money(0.01)
        assert_equal "$1.2345", money(1.2345)
        assert_equal "$10.0000", money(10)
      end

      test "money uses adaptive precision for very small values" do
        # Implementation shows N+1 decimals where N is leading-zero position of first significant digit
        assert_equal "$0.0050",     money(0.005)
        assert_equal "$0.00050",    money(0.0005)
        assert_equal "$0.0010",     money(0.001)
        assert_equal "$0.0000010",  money(0.000001)
      end

      # event_type_class

      test "event_type_class maps known types to badge classes" do
        assert_equal "au-badge--request", event_type_class("request")
        assert_equal "au-badge--job",     event_type_class("job")
        assert_equal "au-badge--task",    event_type_class("task")
      end

      test "event_type_class falls back to custom for unknown types" do
        assert_equal "au-badge--custom", event_type_class("unknown")
        assert_equal "au-badge--custom", event_type_class(nil)
        assert_equal "au-badge--custom", event_type_class("")
      end

      # progress_width

      test "progress_width returns proportional percentage clamped to min_percent" do
        assert_equal 50.0, progress_width(50, 100)
        assert_equal 100.0, progress_width(100, 100)
        assert_equal 10.0, progress_width(1, 100)  # min_percent default 10
      end

      test "progress_width returns 0 for non-positive values or max" do
        assert_equal 0, progress_width(0, 100)
        assert_equal 0, progress_width(-5, 100)
        assert_equal 0, progress_width(50, 0)
      end

      # human_duration_ms

      test "human_duration_ms handles zero and negative" do
        assert_equal "0ms", human_duration_ms(0)
        assert_equal "0ms", human_duration_ms(-1)
        assert_equal "0ms", human_duration_ms(nil)
      end

      test "human_duration_ms formats sub-second as ms" do
        assert_equal "150ms", human_duration_ms(150)
        assert_equal "999ms", human_duration_ms(999)
      end

      test "human_duration_ms formats seconds with one decimal" do
        assert_equal "1.5s", human_duration_ms(1500)
        assert_equal "59.9s", human_duration_ms(59_900)
      end

      test "human_duration_ms formats minutes" do
        assert_equal "1m 0s", human_duration_ms(60_000)
        assert_equal "2m 30s", human_duration_ms(150_000)
      end

      # bar_height_pct

      test "bar_height_pct returns min height for zero max" do
        assert_equal 2, bar_height_pct(50, 0)
        assert_equal 2, bar_height_pct(0, 100)
      end

      test "bar_height_pct returns proportional percentage" do
        assert_equal 50.0, bar_height_pct(50, 100)
        assert_equal 100.0, bar_height_pct(100, 100)
      end

      test "bar_height_pct clamps to minimum 2%" do
        # 0.5% would round to 0.5 but min is 2
        assert_equal 2, bar_height_pct(1, 1000)
      end

      # trends_chart_subtitle

      test "trends_chart_subtitle returns canned text for short periods" do
        assert_equal "Last hour · 5-minute buckets",   trends_chart_subtitle("1h", Time.now)
        assert_equal "Last 24 hours · 1-hour buckets", trends_chart_subtitle("24h", Time.now)
      end

      test "trends_chart_subtitle returns date range for 7d and 30d" do
        result = trends_chart_subtitle("7d", Time.parse("2026-05-01"))
        assert_includes result, "1 May"
      end

      # delta_class

      test "delta_class maps positive to up, negative to down, nil to neutral" do
        assert_equal "au-delta--up",      delta_class(5.0)
        assert_equal "au-delta--down",    delta_class(-5.0)
        assert_equal "au-delta--neutral", delta_class(nil)
      end

      test "delta_class treats zero as not-up" do
        # 0 > 0 is false, so it returns down per current implementation
        assert_equal "au-delta--down", delta_class(0)
      end

      # delta_label

      test "delta_label shows arrow and percentage with sign-aware direction" do
        assert_equal "↑ 5.0%",  delta_label(5.0)
        assert_equal "↓ 3.2%",  delta_label(-3.2)
        assert_equal "—",       delta_label(nil)
      end

      # event_tags_html

      test "event_tags_html returns empty for non-hash, empty hash, or nil" do
        assert_equal "", event_tags_html(nil)
        assert_equal "", event_tags_html({})
        assert_equal "", event_tags_html("not a hash")
      end

      test "event_tags_html renders one badge per tag" do
        html = event_tags_html({ env: "prod", region: "eu-west" })
        assert_includes html, "env: prod"
        assert_includes html, "region: eu-west"
        assert_includes html, "au-badge--tag"
      end

      # range_label

      test "range_label maps known ranges to human strings" do
        assert_equal "last 1 hour",    range_label("1h")
        assert_equal "last 24 hours",  range_label("24h")
        assert_equal "last 7 days",    range_label("7d")
        assert_equal "last 30 days",   range_label("30d")
      end

      test "range_label echoes unknown range" do
        assert_equal "foo", range_label("foo")
      end
    end
  end
end

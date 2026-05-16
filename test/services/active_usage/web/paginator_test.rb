require "test_helper"

module ActiveUsage
  module Web
    class PaginatorTest < ActiveSupport::TestCase
      test "defaults page to 1, per_page to PER_PAGE constant" do
        p = Paginator.new(total_count: 100)
        assert_equal 1, p.page
        assert_equal Paginator::PER_PAGE, p.per_page
      end

      test "coerces page and per_page to integers" do
        p = Paginator.new(total_count: "50", page: "3", per_page: "20")
        assert_equal 50, p.total_count
        assert_equal 3, p.page
        assert_equal 20, p.per_page
      end

      test "clamps page below 1 to 1" do
        assert_equal 1, Paginator.new(total_count: 100, page: 0).page
        assert_equal 1, Paginator.new(total_count: 100, page: -5).page
        assert_equal 1, Paginator.new(total_count: 100, page: nil).page
      end

      test "clamps page above total_pages to last page" do
        p = Paginator.new(total_count: 25, per_page: 10, page: 999)
        assert_equal 3, p.page
      end

      test "total_pages is at least 1 even when empty" do
        assert_equal 1, Paginator.new(total_count: 0).total_pages
        assert_equal 1, Paginator.new(total_count: 0, page: 1).total_pages
      end

      test "total_pages rounds up partial pages" do
        assert_equal 3, Paginator.new(total_count: 21, per_page: 10).total_pages
        assert_equal 2, Paginator.new(total_count: 20, per_page: 10).total_pages
      end

      test "offset is zero on first page" do
        assert_equal 0, Paginator.new(total_count: 100, page: 1, per_page: 10).offset
      end

      test "offset increases linearly" do
        assert_equal 10, Paginator.new(total_count: 100, page: 2, per_page: 10).offset
        assert_equal 40, Paginator.new(total_count: 100, page: 5, per_page: 10).offset
      end

      test "first_page? and last_page? predicates" do
        single = Paginator.new(total_count: 5, per_page: 10)
        assert single.first_page?
        assert single.last_page?

        first = Paginator.new(total_count: 50, per_page: 10, page: 1)
        assert first.first_page?
        refute first.last_page?

        last = Paginator.new(total_count: 50, per_page: 10, page: 5)
        refute last.first_page?
        assert last.last_page?
      end

      test "prev_page is nil on first page, otherwise page - 1" do
        assert_nil Paginator.new(total_count: 50, per_page: 10, page: 1).prev_page
        assert_equal 2, Paginator.new(total_count: 50, per_page: 10, page: 3).prev_page
      end

      test "next_page is nil on last page, otherwise page + 1" do
        assert_nil Paginator.new(total_count: 50, per_page: 10, page: 5).next_page
        assert_equal 4, Paginator.new(total_count: 50, per_page: 10, page: 3).next_page
      end

      test "slice returns correct page of array" do
        array = (1..25).to_a
        page1 = Paginator.new(total_count: 25, per_page: 10, page: 1).slice(array)
        page2 = Paginator.new(total_count: 25, per_page: 10, page: 2).slice(array)
        page3 = Paginator.new(total_count: 25, per_page: 10, page: 3).slice(array)

        assert_equal (1..10).to_a,  page1
        assert_equal (11..20).to_a, page2
        assert_equal (21..25).to_a, page3
      end

      test "slice on empty array returns empty array" do
        assert_equal [], Paginator.new(total_count: 0).slice([])
      end
    end
  end
end

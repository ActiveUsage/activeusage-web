module ActiveUsage
  module Web
    class Paginator
      PER_PAGE = 10

      attr_reader :page, :per_page, :total_count

      def initialize(total_count:, page: 1, per_page: PER_PAGE)
        @total_count = total_count.to_i
        @per_page    = per_page.to_i
        @page        = [ [ page.to_i, 1 ].max, total_pages ].min
      end

      def offset
        (page - 1) * per_page
      end

      def total_pages
        [ (total_count.to_f / per_page).ceil, 1 ].max
      end

      def first_page? = page <= 1
      def last_page?  = page >= total_pages
      def prev_page   = first_page? ? nil : page - 1
      def next_page   = last_page?  ? nil : page + 1

      def slice(array)
        array[offset, per_page] || []
      end
    end
  end
end

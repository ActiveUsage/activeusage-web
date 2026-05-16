module ActiveUsage
  module Web
    module IconHelper
      ICONS = {
        overview: <<~SVG.freeze,
          <rect x="3" y="3" width="7" height="7" rx="1"/>
          <rect x="14" y="3" width="7" height="7" rx="1"/>
          <rect x="3" y="14" width="7" height="7" rx="1"/>
          <rect x="14" y="14" width="7" height="7" rx="1"/>
        SVG
        trends: <<~SVG.freeze,
          <polyline points="3,17 9,11 13,15 21,5"/>
          <polyline points="15,5 21,5 21,11"/>
        SVG
        workloads: <<~SVG.freeze,
          <line x1="8" y1="6"  x2="21" y2="6"/>
          <line x1="8" y1="12" x2="21" y2="12"/>
          <line x1="8" y1="18" x2="21" y2="18"/>
          <circle cx="4" cy="6"  r="1.2"/>
          <circle cx="4" cy="12" r="1.2"/>
          <circle cx="4" cy="18" r="1.2"/>
        SVG
        sql_queries: <<~SVG.freeze,
          <ellipse cx="12" cy="5"  rx="8" ry="3"/>
          <path    d="M4 5v6c0 1.7 3.6 3 8 3s8-1.3 8-3V5"/>
          <path    d="M4 11v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6"/>
        SVG
        events: <<~SVG.freeze,
          <circle cx="12" cy="12" r="9"/>
          <polyline points="12,7 12,12 16,14"/>
        SVG
        cost_rates: <<~SVG.freeze
          <line x1="12" y1="3"  x2="12" y2="21"/>
          <path d="M17 7H9.5a2.5 2.5 0 0 0 0 5h5a2.5 2.5 0 0 1 0 5H7"/>
        SVG
      }.freeze

      def au_icon(name, size: 14)
        body = ICONS.fetch(name)
        tag.svg(body.html_safe,
                class: "au-sidebar-link-icon",
                width: size, height: size, viewBox: "0 0 24 24",
                fill: "none", stroke: "currentColor",
                "stroke-width": 1.75, "stroke-linecap": "round", "stroke-linejoin": "round")
      end
    end
  end
end

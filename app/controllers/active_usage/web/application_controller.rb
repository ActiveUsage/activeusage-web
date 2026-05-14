module ActiveUsage
  module Web
    class ApplicationController < ActionController::Base
      http_basic_authenticate_with(
        name: "activeusage",
        password: ENV.fetch("ACTIVEUSAGE_PASSWORD") { Rails.application.credentials.active_usage.password }
      )
    end
  end
end

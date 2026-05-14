Rails.application.routes.draw do
  mount ActiveUsage::Web::Engine => "/active_usage-web"
end

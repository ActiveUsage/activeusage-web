Rails.application.routes.draw do
  mount ActiveUsage::Web::Engine => "/activeusage"
end

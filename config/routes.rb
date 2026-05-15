ActiveUsage::Web::Engine.routes.draw do
  resources :configurations, only: %i[index new create]
  root to: "home#index"
end

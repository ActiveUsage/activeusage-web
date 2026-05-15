ActiveUsage::Web::Engine.routes.draw do
  resources :configurations
  root to: "home#index"
end

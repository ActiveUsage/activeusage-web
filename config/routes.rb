ActiveUsage::Web::Engine.routes.draw do
  resources :cost_rates,     only: %i[index new create]
  resources :trends,         only: :index
  resources :workloads,      only: :index
  resources :sql_queries,    only: :index
  resources :events,         only: :index

  root to: "home#index"
end

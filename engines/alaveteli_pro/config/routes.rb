AlaveteliPro::Engine.routes.draw do
  # Don't define a root_path because it will be clobbered by the app we're
  # mounted in's root_path (see ApplicationHelper#method_missing for why).
  get "/", to: 'home#index'
  get "/secret", to: 'home#secret'
end

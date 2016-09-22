module AlaveteliPro
  class Engine < ::Rails::Engine
    isolate_namespace AlaveteliPro

    config.autoload_paths += %W(#{config.root}/app/models/concerns)

    config.generators do |g|
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
      g.template_engine :erb
    end
  end
end

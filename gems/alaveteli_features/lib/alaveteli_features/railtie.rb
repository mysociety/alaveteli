require 'alaveteli_features/helpers'

module AlaveteliFeatures
  class Railtie < Rails::Railtie
    initializer "alaveteli_features.helpers" do
      ActiveSupport.on_load :action_view do
        include AlaveteliFeatures::Helpers
      end
      ActiveSupport.on_load :action_controller do
        include AlaveteliFeatures::Helpers
      end
    end
    generators do
      require 'alaveteli_features/generators/alaveteli_features/install/install_generator'
    end
  end
end

# Ensure we get our ApplicationController, not the main app's one
# See notes below http://guides.rubyonrails.org/engines.html#inside-an-engine
require_dependency "alaveteli_pro/application_controller"

module AlaveteliPro
  class HomeController < ApplicationController
    before_filter :authenticate!, only: :secret

    def index
    end

    def secret
    end
  end
end
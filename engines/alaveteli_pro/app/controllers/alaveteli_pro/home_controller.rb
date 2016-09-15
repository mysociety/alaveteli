# Ensure we get our ApplicationController, not the main app's one
# See notes below http://guides.rubyonrails.org/engines.html#inside-an-engine
require_dependency "alaveteli_pro/application_controller"

module AlaveteliPro
  class HomeController < ApplicationController
    def index
    end
  end
end
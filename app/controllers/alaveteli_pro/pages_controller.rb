# -*- encoding : utf-8 -*-
# app/controllers/alaveteli_pro/pages_controller.rb
# Controller for help_pages
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::PagesController < AlaveteliPro::BaseController

  skip_before_action :pro_user_authenticated?

  def show
    if template_exists? "alaveteli_pro/pages/#{params[:id]}"
      render template: "alaveteli_pro/pages/#{params[:id]}"
    else
      raise ActiveRecord::RecordNotFound
    end
  end

end

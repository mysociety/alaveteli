# -*- encoding : utf-8 -*-
class Users::SessionsController < UserController

  before_filter :work_out_post_redirect, :only => [ :new ]
  before_filter :set_request_from_foreign_country, :only => [ :new ]
  before_filter :set_in_pro_area, :only => [ :new ]

  def new
    render :template => 'user/sign'
  end

end

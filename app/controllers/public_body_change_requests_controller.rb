# -*- encoding : utf-8 -*-
class PublicBodyChangeRequestsController < ApplicationController
  before_filter :catch_spam, :only => [:create]

  def new
    @change_request =
      PublicBodyChangeRequest.new

    if params[:body]
      @change_request.public_body =
        PublicBody.find_by_url_name_with_historic(params[:body])
    end

    @title =
      if @change_request.public_body
        _('Ask us to update the email address for {{public_body_name}}',
          :public_body_name => @change_request.public_body.name)
      else
        _('Ask us to add an authority')
      end
  end

  def create
    @change_request =
      PublicBodyChangeRequest.
        from_params(params[:public_body_change_request], @user)

    if @change_request.save
      @change_request.send_message
      redirect_to frontpage_url, :notice => @change_request.thanks_notice
    else
      render :action => 'new'
    end
  end

  private

  def catch_spam
    if params[:public_body_change_request].key?(:comment)
      unless params[:public_body_change_request][:comment].empty?
        redirect_to frontpage_url
      end
    end
  end

end

# -*- encoding : utf-8 -*-
# app/controllers/admin_censor_rule_controller.rb:
# For modifying requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminCensorRuleController < AdminController

  before_filter :set_editor, :only => [:create, :update]
  before_filter :find_and_check_rule, :only => [:edit, :update, :destroy]
  before_filter :set_info_request_and_censor_rule_and_form_url, :only => [:new, :create]

  def index
    @censor_rules = CensorRule.all
  end

  def new
  end

  def create
    if @censor_rule.save
      flash[:notice] = 'Censor rule was successfully created.'
      expire_requests_and_redirect
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    if @censor_rule.update_attributes(censor_rule_params)
      flash[:notice] = 'Censor rule was successfully updated.'
      expire_requests_and_redirect
    else
      render :action => 'edit'
    end
  end

  def destroy
    info_request = @censor_rule.info_request
    user = @censor_rule.user
    @censor_rule.destroy

    flash[:notice] = "Censor rule was successfully destroyed."

    expire_requests_and_redirect
  end

  private

  def set_info_request_and_censor_rule_and_form_url
    if params[:request_id]
      @info_request = InfoRequest.find(params[:request_id])
      @censor_rule = @info_request.censor_rules.build(censor_rule_params)
      @form_url = admin_request_censor_rules_path(@info_request)
    end

    if params[:user_id]
      @censor_user = User.find(params[:user_id])
      @censor_rule = @censor_user.censor_rules.build(censor_rule_params)
      @form_url = admin_user_censor_rules_path(@censor_user)
    end

    if params[:body_id]
      @public_body = PublicBody.find(params[:body_id])
      @censor_rule = @public_body.censor_rules.build(censor_rule_params)
      @form_url = admin_body_censor_rules_path(@public_body)
    end
  end

  def set_editor
    params[:censor_rule][:last_edit_editor] = admin_current_user
  end

  def find_and_check_rule
    @censor_rule = CensorRule.find(params[:id])
    unless (@censor_rule.user || @censor_rule.info_request || @censor_rule.public_body)
      flash[:notice] = 'Only user, request and public body censor rules can be edited'
      redirect_to admin_general_index_path
    end
  end

  def censor_rule_params
    if params[:censor_rule]
      params[:censor_rule].slice(:regexp, :text, :replacement, :last_edit_comment, :last_edit_editor)
    else
      {}
    end
  end

  def expire_requests_and_redirect
    if @censor_rule.info_request
      @censor_rule.info_request.expire
      redirect_to admin_request_url(@censor_rule.info_request)
    elsif @censor_rule.user
      @censor_rule.user.expire_requests
      redirect_to admin_user_url(@censor_rule.user)
    elsif @censor_rule.public_body
      redirect_to admin_body_url(@censor_rule.public_body)
    end
  end
end

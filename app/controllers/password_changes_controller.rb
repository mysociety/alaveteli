# -*- encoding : utf-8 -*-
# app/controllers/password_changes_controller.rb:
# Change a User's password
#
# Copyright (c) 2015 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class PasswordChangesController < ApplicationController
  before_filter :set_pretoken
  before_filter :set_pretoken_hash
  before_filter :set_user_from_session, :only => [:edit, :update]

  def new ; end

  def create
    unless MySociety::Validate.is_valid_email(params[:password_change_user][:email])
      flash[:error] = _("That doesn't look like a valid email address. " \
                        "Please check you have typed it correctly.")
      render :new
      return
    end

    @password_change_user =
      User.where(:email => params[:password_change_user][:email]).first

    if @password_change_user
      uri = edit_password_change_url(@pretoken_hash)

      post_redirect_attrs =
        { :uri => uri,
          :post_params => {},
          :reason_params =>
            { :web => '',
              :email => _('Then you can change your password on {{site_name}}',
                          :site_name => site_name),
              :email_subject => _('Change your password on {{site_name}}',
                                  :site_name => site_name) },
          :circumstance => 'change_password',
          :user => @password_change_user }
      post_redirect = PostRedirect.new(post_redirect_attrs)
      post_redirect.save!

      url = confirm_url(:email_token => post_redirect.email_token)
      UserMailer.
        confirm_login(@password_change_user, post_redirect.reason_params, url).
          deliver
    end

    render :check_email
  end

  def edit
    if @password_change_user
      render :edit
    else
      redirect_to new_password_change_path(@pretoken_hash)
    end
  end

  def update
    if @pretoken
      @pretoken_redirect = PostRedirect.where(:token => @pretoken).first
    end

    if @password_change_user
      @password_change_user.password = params[:password_change_user][:password]
      @password_change_user.password_confirmation =
        params[:password_change_user][:password_confirmation]

      if @password_change_user.save
        session.delete(:change_password_post_redirect_id)
        session[:user_id] ||= @password_change_user.id

        msg = _('Your password has been changed.')

        if @pretoken_redirect
          redirect_to @pretoken_redirect.uri, :notice => msg
        else
          redirect_to show_user_profile_path(@password_change_user.url_name),
                      :notice => msg
        end
      else
        render :edit
      end
    else
      redirect_to new_password_change_path
    end
  end

  protected

  def set_pretoken
    @pretoken = params.fetch(:pretoken, '').blank? ? nil : params[:pretoken]
  end

  def set_pretoken_hash
    @pretoken_hash = @pretoken ? { :pretoken => @pretoken } : {}
  end

  def set_user_from_session
    @password_change_user ||=
      if session[:change_password_post_redirect_id]
        PostRedirect.find(session[:change_password_post_redirect_id]).user
      else
        nil
      end
  end

end

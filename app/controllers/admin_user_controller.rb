# -*- encoding : utf-8 -*-
# app/controllers/admin_user_controller.rb:
# Controller for viewing user accounts from the admin interface.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminUserController < AdminController

  before_filter :set_admin_user, :only => [ :show,
                                            :edit,
                                            :update,
                                            :show_bounce_message,
                                            :clear_bounce,
                                            :login_as,
                                            :clear_profile_photo ]

  before_filter :clear_roles,
                :check_role_authorisation,
                :check_role_requirements, :only => [ :update ]

  def index
    @query = params[:query]

    @sort_options = index_sort_options

    @sort_order =
      @sort_options.key?(params[:sort_order]) ? params[:sort_order] : 'name_asc'

    users = if @query
      User.where(["lower(name) LIKE lower('%'||?||'%') OR " \
                  "lower(email) LIKE lower('%'||?||'%')", @query, @query])
    else
      User
    end

    @admin_users =
      users.order(@sort_options[@sort_order]).
        paginate(:page => params[:page], :per_page => 100)
  end

  def show
    @info_requests = @admin_user.info_requests
    @comments = @admin_user.comments
    if cannot? :admin, AlaveteliPro::Embargo
      @info_requests = @info_requests.not_embargoed
      @comments = @admin_user.comments.not_embargoed
    end
    @info_requests = @info_requests.paginate(:page => params[:page],
                                             :per_page => 100)
  end

  def edit
  end

  def update
    if @admin_user.update_attributes(user_params)
      if @admin_user == @user && !@admin_user.is_admin?
        flash[:notice] = 'User successfully updated - ' \
                         'you are no longer an admin.'
        session[:using_admin] = nil
        session[:admin_name] = nil
        redirect_to root_path
      else
        flash[:notice] = 'User successfully updated.'
        redirect_to admin_user_url(@admin_user)
      end
    else
      render :action => 'edit'
    end
  end

  def banned
    @banned_users =
      User.where("ban_text <> ''").
        order('name ASC').
          paginate(:page => params[:page], :per_page => 100)
  end

  def show_bounce_message
  end

  def clear_bounce
    @admin_user.email_bounced_at = nil
    @admin_user.email_bounce_message = ""
    @admin_user.save!
    redirect_to admin_user_url(@admin_user)
  end

  def login_as
    if cannot? :login_as, @admin_user
      flash[:error] = "You don't have permission to log in as #{@admin_user.name}"
      return redirect_to admin_user_path(@admin_user)
    end
    post_redirect = PostRedirect.new( :uri => user_url(@admin_user),
                                      :user_id => @admin_user.id,
                                      :circumstance => "login_as" )
    post_redirect.save!
    url = confirm_url(:email_token => post_redirect.email_token)
    redirect_to url
  end

  def clear_profile_photo
    if @admin_user.profile_photo
      @admin_user.profile_photo.destroy
    end

    flash[:notice] = "Profile photo cleared"
    redirect_to admin_user_url(@admin_user)
  end

  def modify_comment_visibility
    Comment.where(:id => params[:comment_ids]).
      update_all(:visible => !params[:hide_selected])
    redirect_to :back
  end

  private

  def user_params
    if params[:admin_user]
      params.require(:admin_user).permit(:name,
                                         :email,
                                         {:role_ids => []},
                                         :ban_text,
                                         :about_me,
                                         :no_limit,
                                         :can_make_batch_requests,
                                         :confirmed_not_spam)
    else
      {}
    end
  end

  def clear_roles
    # Clear roles if none checked
    params[:admin_user][:role_ids] ||= []
  end

  # Check all changed roles exist, current user can grant and revoke them
  # and requirements are met
  def check_role_authorisation
    all_allowed = changed_role_ids.all? do |role_id|
      role = Role.where(:id => role_id).first
      role && @user.can_admin_role?(role.name.to_sym)
    end
    unless all_allowed
      flash[:error] = "Not permitted to change roles"
      render :action => 'edit' and return false
    end
  end

  def changed_role_ids
    params[:admin_user][:role_ids].map!{ |role_id| role_id.to_i }
    (params[:admin_user][:role_ids] - @admin_user.role_ids) |
    (@admin_user.role_ids - params[:admin_user][:role_ids])
  end

  def check_role_requirements
    role_names = Role.
                   where(:id => params[:admin_user][:role_ids]).
                     pluck(:name).to_a.map{ |role| role.to_sym }
    missing_required = Hash.new { |h, k| h[k] = [] }
    role_names.each do |role_name|
      Role.requires(role_name).each do |required_role_name|
        unless role_names.include?(required_role_name)
          missing_required[role_name] << required_role_name
        end
      end
    end
    unless missing_required.empty?
      flash[:error] = "Role requirements not met:"
      missing_required.each do |key, value|
        flash[:error] += " #{key} requires #{value.to_sentence}"
      end
      render :action => 'edit' and return false
    end

  end

  def set_admin_user
    # Don't use @user as that is any logged in user
    @admin_user = User.find(params[:id])
  end

  def index_sort_options
    { 'name_asc' => 'name ASC',
      'name_desc' => 'name DESC',
      'created_at_desc' => 'created_at DESC',
      'created_at_asc' => 'created_at ASC',
      'updated_at_desc' => 'updated_at DESC',
      'updated_at_asc' => 'updated_at ASC' }
  end
end

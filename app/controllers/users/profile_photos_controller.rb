##
# Controller to allow users to set, crop and clear their profile photo, and to
# serve profile photos
#
class Users::ProfilePhotosController < ApplicationController
  skip_before_action :html_response, only: [
    :get_draft_profile_photo, :get_profile_photo
  ]

  before_action :set_display_user, only: :get_profile_photo

  def set_profile_photo
    # check they are logged in (the upload photo option is anyway only available when logged in)
    unless authenticated?
      msg = _("You need to be logged in to change your profile photo.")
      redirect_to frontpage_url, error: msg
      return
    end
    if request.post? && params[:submitted_draft_profile_photo].present?
      if @user.suspended?
        msg = _('Suspended users cannot edit their profile')
        redirect_to set_profile_photo_path, error: msg
        return
      end

      # check for uploaded image
      file_name = nil
      file_content = nil
      unless params[:file].nil?
        file_name = params[:file].original_filename
        file_content = params[:file].read
      end

      # validate it
      @draft_profile_photo = ProfilePhoto.new(data: file_content, draft: true)
      unless @draft_profile_photo.valid?
        # error page (uses @profile_photo's error fields in view to show errors)
        render :set_draft_profile_photo
        return
      end
      @draft_profile_photo.save!

      if params[:automatically_crop]
        # no javascript, crop automatically
        @profile_photo = ProfilePhoto.new(data: @draft_profile_photo.data, draft: false)
        @user.set_profile_photo(@profile_photo)
        @draft_profile_photo.destroy
        flash[:notice] = _("Thank you for updating your profile photo")
        redirect_to user_url(@user)
        return
      end

      session[:draft_profile_photo_id] = @draft_profile_photo.id
      render :set_crop_profile_photo
      nil
    elsif request.post? && params[:submitted_crop_profile_photo].present?
      # crop the draft photo according to jquery parameters and set it as the users photo
      draft_profile_photo = ProfilePhoto.find_by!(
        id: session.delete(:draft_profile_photo_id), draft: true
      )
      @profile_photo = ProfilePhoto.new(data: draft_profile_photo.data, draft: false,
                                        x: params[:x], y: params[:y], w: params[:w], h: params[:h])
      @user.set_profile_photo(@profile_photo)
      draft_profile_photo.destroy

      if @user.get_about_me_for_html_display.empty?
        flash[:notice] = {
          partial: "users/profile_photos/update_profile_photo"
        }
        redirect_to edit_profile_about_me_url
      else
        flash[:notice] = _("Thank you for updating your profile photo")
        redirect_to user_url(@user)
      end
    else
      render :set_draft_profile_photo
    end
  end

  def clear_profile_photo
    # check they are logged in (the upload photo option is anyway only available when logged in)
    unless authenticated?
      msg = _("You need to be logged in to clear your profile photo.")
      redirect_to frontpage_url, error: msg
      return
    end

    @user.profile_photo.destroy if @user.profile_photo

    flash[:notice] = _("You've now cleared your profile photo")
    redirect_to user_url(@user)
  end

  # before they've cropped it
  def get_draft_profile_photo
    unless params[:id].to_i == session[:draft_profile_photo_id]
      raise ActiveRecord::RecordNotFound
    end

    profile_photo = ProfilePhoto.find_by!(id: params[:id], draft: true)
    render body: profile_photo.data,
           content_type: 'image/png'
  end

  # actual profile photo of a user
  def get_profile_photo
    long_cache
    unless @display_user.profile_photo
      raise ActiveRecord::RecordNotFound, "user has no profile photo, url_name=" + params[:url_name]
    end

    render body: @display_user.profile_photo.data,
           content_type: 'image/png'
  end

  private

  def set_display_user
    @display_user = User.where(email_confirmed: true).
                         friendly.find(params[:url_name])
  end
end

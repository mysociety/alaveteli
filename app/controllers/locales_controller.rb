##
# Controller responsible for switching the user's locale.
#
class LocalesController < ApplicationController
  def update
    locale = AlaveteliLocalization.set_session_locale(params[:locale])
    cookies[:locale] = locale
    current_user&.update_column(:locale, locale)

    redirect_to url_from(params[:return_to]) || root_path
  end
end

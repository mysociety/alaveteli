# -*- encoding : utf-8 -*-
# Managing a User's email alerts.
class Users::EmailAlertsController < ApplicationController
  def destroy
    unless User::EmailAlerts.disable_by_token(CGI.unescape(params[:token]))
      redirect_to root_path, flash: { error: _('Invalid token') }
    end
  end
end

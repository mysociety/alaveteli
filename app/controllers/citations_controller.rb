##
# Controller to create a new Citation for an InfoRequest or an InfoRequestBatch.
#
class CitationsController < ApplicationController
  before_action :authenticate

  def new
  end

  def create
  end

  private

  def authenticate
    authenticated?(
      web: _('To add a citation'),
      email: _('Then you can add citations'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end
end

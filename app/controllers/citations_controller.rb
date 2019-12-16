##
# Controller to create a new Citation for an InfoRequest or an InfoRequestBatch.
#
class CitationsController < ApplicationController
  before_action :authenticate
  before_action :load_info_request_and_authorise

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

  def info_request
    @info_request ||= InfoRequest.find_by_url_title!(params[:url_title])
  end

  def load_info_request_and_authorise
    if cannot?(:read, info_request)
      return render_hidden('request/hidden', response_code: 404)
    end

    authorize! :create_citation, info_request
  end
end

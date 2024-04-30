##
# Controller to create a new Citation for an InfoRequest or an InfoRequestBatch.
#
class CitationsController < ApplicationController
  before_action :authenticate
  before_action :load_info_request_and_authorise
  before_action :set_in_pro_area
  before_action :set_no_crawl_headers

  def new
    @citation = current_user.citations.build
  end

  def create
    @citation = current_user.citations.build(citation_params)
    @citation.citable = citable

    if @citation.save
      notice = _('Citation successfully created.')
      redirect_to show_request_path(info_request.url_title),
                  notice: notice
    else
      render :new
    end
  end

  private

  def authenticate
    authenticated? || ask_to_login(
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

  def set_in_pro_area
    @in_pro_area = current_user.is_pro? && info_request.user == current_user
  end

  def citation_params
    params.require(:citation).permit(:source_url, :type)
  end

  def citable
    (info_request.info_request_batch if params[:applies_to_batch_request]) ||
      info_request
  end
end

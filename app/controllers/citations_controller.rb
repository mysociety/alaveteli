##
# Controller to create a new Citation for an InfoRequest or an InfoRequestBatch.
#
class CitationsController < ApplicationController
  before_action :authenticate
  before_action :load_resource_and_authorise
  before_action :set_in_pro_area

  def new
    @citation = current_user.citations.build
  end

  def create
    @citation = current_user.citations.build(citation_params)

    if @citation.save
      notice = _('Citation successfully created.')
      case @citable
      when InfoRequest
        redirect_to show_request_path(citable.url_title), notice: notice
      when InfoRequestBatch
        redirect_to info_request_batch_path(citable), notice: notice
      end
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

  def resource
    case params.fetch(:resource, 'InfoRequest')
    when 'InfoRequest'
      @resource ||= InfoRequest.find_by_url_title!(params[:url_title])
    when 'InfoRequestBatch'
      @resource ||= InfoRequestBatch.find_by_id!(params[:info_request_batch_id])
    end
  end

  def load_resource_and_authorise
    if cannot?(:read, resource)
      return render_hidden('request/hidden', response_code: 404)
    end

    authorize! :create_citation, resource
  end

  def set_in_pro_area
    @in_pro_area = current_user.is_pro? && resource.user == current_user
  end

  def citation_params
    params.require(:citation).permit(:source_url, :type).
      with_defaults(citable: citable)
  end

  def citable
    @citable = resource.info_request_batch if params[:applies_to_batch_request]
    @citable ||= resource
  end
end

class AdminPublicBodyChangeRequestsController < AdminController
  include Admin::Searchable
  include Admin::Sortable

  before_action :set_change_request, only: [:destroy, :edit, :update]

  sortable default: :updated_at_desc, relevance: :indexed_search?,
           only: [:index]

  def index
    @query = params[:query]
    @query = nil if @query == ''

    if @query.nil?
      change_requests = PublicBodyChangeRequest
    else
      change_requests = PublicBodyChangeRequest.search_scope(
        @query,
        backend: :postgresql,
        admin_mode: true,
        exact_mode: true
      )
    end

    @change_requests = measure_search(
      sorted(
        change_requests.includes(public_body: :translations)
      ).paginate(page: params[:page], per_page: 100)
    )
  end

  def destroy
    @change_request.destroy

    redirect_to admin_change_requests_path
  end

  def edit
    @full_edit = params[:full_edit]
    if @full_edit
      @title = 'Edit change request'
    else
      @title = 'Close change request'
    end
  end

  def update
    @full_edit = params[:commit] == 'Save'

    if @full_edit

      @change_request.update!(change_request_params)
      flash[:notice] = "Change request successfully updated."

      render action: 'edit'
    else
      @change_request.close!

      if params[:subject] && params[:response]
        @change_request.send_response(params[:subject], params[:response])
        flash[:notice] =
          'The change request has been closed and the user has been notified'
      else
        flash[:notice] = 'The change request has been closed'
      end

      redirect_to admin_general_index_path
    end
  end

  private

  def change_request_params
    if params[:change_request]
      params.
        require(:change_request).
        permit(
          :user_name,
          :user_email,
          :public_body_name,
          :public_body_email,
          :source_url,
          :notes,
          :is_open
        ) 
    else
      {}
    end
  end

  def set_change_request
    @change_request = PublicBodyChangeRequest.find(params[:id])
  end
end

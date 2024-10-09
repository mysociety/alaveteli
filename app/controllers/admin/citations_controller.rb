class Admin::CitationsController < AdminController
  def index
    @query = params[:query]

    citations = (
      if @query
        Citation.search(@query)
      else
        Citation
      end
    )

    @citations =
      citations.
      order(created_at: :desc).
      paginate(page: params[:page], per_page: 50)
  end
end

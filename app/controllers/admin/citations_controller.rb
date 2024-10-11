class Admin::CitationsController < AdminController
  before_action :find_citation, except: :index

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

  def edit
  end

  def update
    if @citation.update(citation_params)
      redirect_to admin_citations_path, notice: 'Citation updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    @citation.destroy
    redirect_to admin_citations_path, notice: 'Citation deleted successfully.'
  end

  private

  def find_citation
    @citation = Citation.find(params[:id])
  end

  def citation_params
    params.require(:citation).permit(:source_url, :title, :description)
  end
end

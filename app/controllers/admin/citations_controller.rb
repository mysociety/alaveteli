class Admin::CitationsController < AdminController
  include Admin::Searchable
  include Admin::Sortable

  before_action :find_citation, except: :index

  sortable default: :updated_at_desc, relevance: :indexed_search?,
           only: [:index]

  def index
    @query = params[:query] || nil
    @page = get_search_page_from_params

    citations = citation_scope

    if cannot? :admin, AlaveteliPro::Embargo
      citations = citations.not_embargoed
    end

    @citations = measure_search(
      sorted(
        citations.includes(:citable, :user)
      ).paginate(page: @page, per_page: 100)
    )
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

  def citation_scope
    return Citation unless @query.present?

    legacy_search? ? legacy_citation_scope : indexed_citation_scope
  end

  def legacy_citation_scope
    Citation.search(@query)
  end

  def indexed_citation_scope
    Citation.search_scope(
      @query,
      backend: :postgresql,
      admin_mode: true,
      exact_mode: true
    )
  end

  def find_citation
    @citation = Citation.find(params[:id])
  end

  def citation_params
    params.require(:citation).permit(:source_url, :title, :description)
  end
end

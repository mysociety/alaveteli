# Handles citation deletion by admin users
module Admin
  class CitationsController < AdminController
    before_action :find_citation, only: [:destroy]
    layout 'admin'

    def index
      @citations = Citation.all
      return if can?(:admin, AlaveteliPro::Embargo)
      @citations = @citations.reject { |citation| citation.citable.embargo }
    end

    def destroy
      if params[:citation_ids]
        Citation.destroy_citations(params[:citation_ids], admin_current_user)
        flash[:notice] = 'Citation(s) deleted successfully.'
      else
        Citation.log_citation_destruction(@citation, admin_current_user)
        @citation.destroy
        flash[:notice] = 'Citation deleted successfully.'
      end
      redirect_back(fallback_location: root_path)
    end

    private

    def find_citation
      @citation = Citation.find(params[:id]) if params[:id]
    end
  end
end

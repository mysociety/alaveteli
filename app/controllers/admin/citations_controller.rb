# Manages citation deletion by admin users
module Admin
  class CitationsController < AdminController
    before_action :find_citation, only: [:destroy]

    layout 'admin'

    def index
      @citations = Citation.all
      return if can?(:admin, AlaveteliPro::Embargo)
      @citations = @citations.reject { |citation|
  citation.citable.embargo
}
    end

    def destroy
      if params[:citation_ids]
        @citations = Citation.where(id: params[:citation_ids])
        @citations.each do |citation|
          log_citation_destruction(citation)
        end
        @citations.destroy_all
        flash[:notice] = 'Citation(s) deleted successfully.'
      else
        log_citation_destruction(@citation)
        @citation.destroy
        flash[:notice] = 'Citation deleted successfully.'
      end
      redirect_back(fallback_location: root_path)
    end

    private

    def find_citation
      @citation = Citation.find(params[:id]) if params[:id]
    end

    def log_citation_destruction(citation)
      return unless citation.citable.is_a?(InfoRequest)
      citation.citable.log_event(
        'destroy_citation',
        editor: admin_current_user,
        deleted_citation_id: citation.id
      )
    end
  end
end

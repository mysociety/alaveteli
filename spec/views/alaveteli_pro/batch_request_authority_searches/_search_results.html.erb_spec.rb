require 'spec_helper'

RSpec.describe '_search_results' do
  let(:draft_batch_request) { AlaveteliPro::DraftInfoRequestBatch.new }

  def render_view(locals)
    render(
      partial: "alaveteli_pro/batch_request_authority_searches/search_results",
      locals: locals
    )
  end

  describe "when a search has been performed" do
    let!(:authority_1) { FactoryBot.create(:public_body) }
    let!(:authority_2) { FactoryBot.create(:public_body) }
    let!(:authority_3) { FactoryBot.create(:public_body) }

    before do
      allow(view).to receive(:mode)
      allow(view).to receive(:category_tag)
    end

    describe "and there are some results" do
      let(:search) do
        build_search_results(
          items: [authority_1, authority_2, authority_3],
          total: 3
        )
      end

      it "renders search results" do
        expect(search).to be_present
        expect(search.results).to be_present
        render_view(search: search,
                    query: authority_1.name,
                    draft_batch_request: draft_batch_request,
                    body_ids_added: [],
                    page: 1,
                    per_page: 25,
                    result_limit: 3)
        expect(rendered).to have_text(authority_1.name)
      end
    end

    describe 'and there are no results' do
      let(:query) { 'search term' }
      let(:search) { build_search_results(items: [], total: 0) }

      it 'renders a no results message' do
        render_view(
          search: search,
          query: query,
          draft_batch_request: draft_batch_request
        )
        expect(rendered).to have_text(
          'Sorry, no authorities matched that search'
        )
      end
    end
  end

  describe "when no search has been performed" do
    it "renders nothing" do
      render_view(
        search: nil,
        query: nil,
        draft_batch_request: draft_batch_request
      )
      expect(rendered).to eq ""
    end
  end
end

# -*- encoding : utf-8 -*-
require 'spec_helper'

describe '_search_results.html.erb' do
  def render_view(locals)
    render(:partial => "alaveteli_pro/batch_request_authority_searches/search_results",
           :locals => locals)
  end

  describe "when a search has been performed" do
    let!(:authority_1) { FactoryGirl.create(:public_body) }
    let!(:authority_2) { FactoryGirl.create(:public_body) }
    let!(:authority_3) { FactoryGirl.create(:public_body) }

    before do
      update_xapian_index
    end

    describe "and there are some results" do
      let(:search) { ActsAsXapian::Search.new([PublicBody], authority_1.name, :limit => 3 ) }

      it "renders search results" do
        # TODO: This fails, as the view doesn't render anything, but I
        # can't figure out why. It passes if this example runs first!
        expect(search).to be_present
        expect(search.results).to be_present
        render_view(:search => search,
                    :query => authority_1.name,
                    :draft_batch_request => AlaveteliPro::DraftInfoRequestBatch.new,
                    :body_ids_added => [],
                    :page => 1,
                    :per_page => 25,
                    :result_limit => 3)
        expect(rendered).to have_text(authority_1.name)
      end
    end

    describe 'and there are no results' do
      let(:query) { 'serach term' }
      let(:search) { ActsAsXapian::Search.new([PublicBody], query, limit: 3) }

      it 'renders a no results message' do
        render_view(
          search: search,
          query: query,
        )
        expect(rendered).to have_text(
          'Sorry, no authorities matched that search'
        )
      end
    end
  end

  describe "when no search has been performed" do
    it "renders nothing" do
      render_view(:search => nil, :query => nil)
      expect(rendered).to eq ""
    end
  end
end

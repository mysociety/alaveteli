require 'spec_helper'

def render_view
  render partial: self.class.top_level_description,
         locals: stub_locals
end

describe 'request/citations' do
  let(:info_request) { FactoryBot.create(:info_request) }

  let(:ability) { Object.new.extend(CanCan::Ability) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:current_user).and_return(info_request.user)
  end

  context 'with no citations' do
    let(:stub_locals) { { citations: [], info_request: info_request } }

    context 'the current_user cannot create a citation' do
      before { ability.cannot :create_citation, info_request }
      before { render_view }

      it 'renders nothing' do
        expect(rendered).to eq("\n")
      end
    end

    context 'the current_user can create a citation' do
      before { ability.can :create_citation, info_request }
      before { render_view }

      it 'renders the section' do
        expect(rendered).to match(/In the News/)
      end

      it 'renders the blank slate text' do
        expect(rendered).to match(/Has this request been referenced/)
      end

      it 'renders the link to add citations' do
        expect(rendered).
          to match(new_citation_path(url_title: info_request.url_title))
      end
    end
  end

  context 'with citations' do
    let(:stub_locals) do
      { citations: FactoryBot.build_list(:citation, 3),
        info_request: info_request }
    end

    context 'the current_user cannot create a citation' do
      before { ability.cannot :create_citation, info_request }
      before { render_view }

      it 'renders the section' do
        expect(rendered).to match(/In the News/)
      end

      it 'does not render the blank slate text' do
        expect(rendered).not_to match(/Has this request been referenced/)
      end

      it 'renders the citations' do
        expect(rendered).to match(/citations-list/)
      end

      it 'does not render the link to add a citation' do
        expect(rendered).
          not_to match(new_citation_path(url_title: info_request.url_title))
      end
    end

    context 'the current_user can create a citation' do
      before { ability.can :create_citation, info_request }
      before { render_view }

      it 'renders the section' do
        expect(rendered).to match(/In the News/)
      end

      it 'does not render the blank slate text' do
        expect(rendered).not_to match(/Has this request been referenced/)
      end

      it 'renders the citations' do
        expect(rendered).to match(/citations-list/)
      end

      it 'renders the link to add citations' do
        expect(rendered).to match('New Citation')
      end
    end
  end
end

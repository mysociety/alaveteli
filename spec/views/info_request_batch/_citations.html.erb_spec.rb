require 'spec_helper'

def render_view
  render partial: self.class.top_level_description,
         locals: stub_locals
end

RSpec.describe 'info_request_batch/citations' do
  let(:info_request_batch) { FactoryBot.create(:info_request_batch) }

  let(:ability) { Object.new.extend(CanCan::Ability) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:current_user).and_return(info_request_batch.user)
  end

  context 'with no citations' do
    let(:stub_locals) do
      { citations: [], info_request_batch: info_request_batch }
    end

    context 'the current_user cannot create a citation' do
      before { ability.cannot :create_citation, info_request_batch }
      before { render_view }

      it 'renders nothing' do
        expect(rendered).to be_blank
      end
    end

    context 'the current_user can create a citation' do
      before { ability.can :create_citation, info_request_batch }
      before { render_view }

      it 'renders the section' do
        expect(rendered).to match(/FOI in Action/)
      end

      it 'renders the blank slate text' do
        expect(rendered).to match(/Has this batch request been referenced/)
      end

      it 'renders the link to add citations' do
        expect(rendered).
          to match(new_info_request_batch_citation_path(info_request_batch))
      end
    end
  end

  context 'with citations' do
    let(:stub_locals) do
      { citations: FactoryBot.build_list(:citation, 3),
        info_request_batch: info_request_batch }
    end

    context 'the current_user cannot create a citation' do
      before { ability.cannot :create_citation, info_request_batch }
      before { render_view }

      it 'renders the section' do
        expect(rendered).to match(/FOI in Action/)
      end

      it 'renders the citations' do
        expect(rendered).to match(/citations-list/)
      end

      it 'does not render the link to add a citation' do
        expect(rendered).
          not_to match(new_info_request_batch_citation_path(info_request_batch))
      end
    end

    context 'the current_user can create a citation' do
      before { ability.can :create_citation, info_request_batch }
      before { render_view }

      it 'renders the section' do
        expect(rendered).to match(/FOI in Action/)
      end

      it 'renders the citations' do
        expect(rendered).to match(/citations-list/)
      end

      it 'renders the blank slate text' do
        expect(rendered).to match(/Has this batch request been referenced/)
      end

      it 'renders the link to add citations' do
        expect(rendered).to match('Let us know')
      end
    end
  end
end

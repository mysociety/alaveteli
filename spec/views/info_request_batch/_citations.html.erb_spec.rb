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

    before { render_view }

    it 'renders nothing' do
      expect(rendered).to be_blank
    end
  end

  context 'with citations' do
    let(:stub_locals) do
      { citations: FactoryBot.build_list(:citation, 3),
        info_request_batch: info_request_batch }
    end

    before { render_view }

    it 'renders the section' do
      expect(rendered).to match(/In the News/)
    end

    it 'renders the citations' do
      expect(rendered).to match(/citations-list/)
    end
  end
end

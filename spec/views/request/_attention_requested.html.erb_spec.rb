require 'spec_helper'

RSpec.describe 'request/attention_requested' do
  def render_view
    render partial: self.class.top_level_description,
           locals: { info_request: info_request }
  end

  context 'when the request is hidden' do
    let(:info_request) { FactoryBot.build(:info_request, prominence: 'hidden') }

    before { allow(view).to receive(:current_user) }

    it 'shows the request is hidden' do
      render_view
      expect(rendered).to include 'This request has been hidden'
    end
  end

  context 'when the request is requester_only' do
    let(:info_request) do
      FactoryBot.build(:info_request, prominence: 'requester_only')
    end

    before do
      allow(view).to receive(:current_user).and_return(info_request.user)
    end

    it 'shows the request is requester_only' do
      render_view
      expect(rendered).to include 'so that only you, the requester'
    end
  end

  context 'when the request state is not attention_requested' do
    let(:info_request) do
      FactoryBot.build(:info_request, described_state: 'successful')
    end

    it 'shows that the request has been reviewed' do
      render_view
      expect(rendered).to match(/who have not hidden it at this time/)
    end
  end
end

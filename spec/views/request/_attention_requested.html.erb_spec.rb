require 'spec_helper'

describe 'request/attention_requested' do
  def render_view
    render partial: self.class.top_level_description,
           locals: { info_request: info_request }
  end

  context 'when the request is hidden' do
    let(:info_request) do
      instance_double('InfoRequest', prominence: double(is_hidden?: true))
    end

    it 'shows the request is hidden' do
      render_view
      expect(rendered).to match(/This request has prominence 'hidden'/)
    end
  end

  context 'when the request is requester_only' do
    let(:info_request) do
      prominence = double(is_hidden?: false, is_requester_only?: true)
      instance_double('InfoRequest', prominence: prominence)
    end

    it 'shows the request is requester_only' do
      render_view
      expect(rendered).to match(/so that only you the requester/)
    end
  end

  context 'when the request state is not attention_requested' do
    let(:info_request) do
      stubs = {
        prominence: double(is_hidden?: false, is_requester_only?: false),
        described_state: 'successful'
      }

      instance_double('InfoRequest', stubs)
    end

    it 'shows that the request has been reviewed' do
      render_view
      expect(rendered).to match(/who have not hidden it at this time/)
    end
  end
end

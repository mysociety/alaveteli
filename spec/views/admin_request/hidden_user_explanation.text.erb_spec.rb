require 'spec_helper'

RSpec.describe 'admin_request/hidden_user_explanation.text.erb' do
  let(:message) { 'vexatious' }
  let(:template) do
    'admin_request/hidden_user_explanation'
  end

  before do
    render template: template,
           formats: [:text],
           locals: { name_to: 'Bob Smith',
                     info_request: double(title: 'Foo'),
                     info_request_url: 'https://test.host/request/foo',
                     message: message,
                     site_name: 'Alaveteli' }
  end

  it 'interpolates the locals' do
    expect(rendered).to eq(read_described_template_fixture)
  end

  context 'when not_foi message' do
    let(:message) { 'not_foi' }

    it 'renders the correct message partial' do
      expected = 'admin_request/hidden_user_explanation/_not_foi'
      expect(rendered).to render_template(partial: expected)
    end
  end
end

require 'spec_helper'

RSpec.describe 'admin_request/hidden_user_explanation' do
  let(:explanation) do
    "We consider it to be vexatious, and have therefore hidden it from other " \
    "users.\n"
  end

  let(:template) do
    'admin_request/hidden_user_explanation'
  end

  before do
    render template: template,
           formats: [:text],
           locals: { name_to: 'Bob Smith',
                     info_request: double(title: 'Foo'),
                     info_request_url: 'https://test.host/request/foo',
                     explanation: explanation,
                     site_name: 'Alaveteli' }
  end

  it 'interpolates the locals' do
    expect(rendered).to eq(read_described_template_fixture)
  end
end

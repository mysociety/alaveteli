require 'spec_helper'

RSpec.describe 'public_body_change_request_mailer/update_public_body' do
  let(:user) { FactoryBot.create(:user, name: "Test Us'r") }

  let(:public_body) do
    FactoryBot.create(:public_body,
                      name: "Apostrophe's",
                      request_email: 'prev@localhost')
  end

  let(:change_request) do
    FactoryBot.create(
      :update_body_request,
      public_body_email: 'new@localhost',
      public_body: public_body,
      user: user)
  end

  before do
    assign(:change_request, change_request)
    render
  end

  it 'does not add HTMLEntities to the user name' do
    expect(response).to match("Test Us'r would like the email address for")
  end

  it 'does not add HTMLEntities to the public body name' do
    expect(response).to match("email address for Apostrophe's to be updated")
  end

  it 'shows the current email address' do
    expect(response).to match("Current Email:\nprev@localhost")
  end

  it 'shows the proposed email address' do
    expect(response).to match("Proposed Email:\nnew@localhost")
  end
end

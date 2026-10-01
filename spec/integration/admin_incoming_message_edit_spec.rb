require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'Editing the IncomingMessage body' do
  let(:request) { FactoryBot.create(:info_request, :with_incoming) }
  let(:im) { request.incoming_messages.first }

  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it 'destroys the message correctly' do
    using_session(@admin) do
      visit edit_admin_incoming_message_path(im)

      click_button 'Destroy message'
    end

    expect(request.incoming_messages.count).to eq(0)
  end

  it 'erases the message correctly' do
    using_session(@admin) do
      visit edit_admin_incoming_message_path(im)
      fill_in 'incoming_message_erasure_reason', with: 'Super secret'

      click_button 'Erase message'
    end

    expect(im.reload.from_name).to be_nil
    expect(im.reload.subject).to be_nil
  end
end

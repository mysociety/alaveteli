require 'spec_helper'

RSpec.describe 'user_profile/notification_preferences/edit' do
  let(:user) { FactoryBot.build(:user) }

  before :each do
    assign(:user, user)
  end

  it 'renders the form' do
    render
    expect(rendered).to have_css('form')
  end

  it 'renders checkboxes for notification preferences' do
    render
    expect(rendered).to have_css('input[type="checkbox"][name="user[send_daily_summary]"]')
    expect(rendered).to have_css('input[type="checkbox"][name="user[send_immediate_request_alerts]"]')
  end

  it 'renders a save button' do
    render
    expect(rendered).to have_button('Save')
  end
end

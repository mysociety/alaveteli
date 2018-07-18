# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Sending a message to another user' do

  let(:sender) { FactoryBot.create(:user) }
  let(:recipient) { FactoryBot.create(:user, :name => "Awkward > Name") }

  it 'renders a notice to say the message was sent' do
    message = "Your message to Awkward &gt; Name has been sent!"
    using_session(login(sender)) do
      visit contact_user_path :id => recipient.id
      fill_in 'contact_subject', :with => "This is a test"
      fill_in 'contact_message', :with => "Hello, this is a test message"
      click_button('Send message')

      expect(page.body).to include(message)
    end
  end

end

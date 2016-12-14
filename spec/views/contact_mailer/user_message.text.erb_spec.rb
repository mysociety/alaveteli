# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "contact_mailer/user_message" do
  let(:user) { FactoryGirl.create(:user, :name => "Test Us'r") }

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
    assign(:message, "hi!")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:from_user, user)
    render
    expect(response).to match("has used l'Information to send you the message")
  end

  it "does not add HTMLEntities to the user name" do
    assign(:from_user, user)
    render
    expect(response).to match("Test Us'r has used")
    expect(response).not_to match("Test Us&#x27;r")
  end
end

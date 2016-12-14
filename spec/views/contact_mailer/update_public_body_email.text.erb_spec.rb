# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "contact_mailer/update_public_body_email" do
  let(:user) { FactoryGirl.create(:user, :name => "Test Us'r") }
  let(:public_body) do
    FactoryGirl.create(:public_body, :name => "Apostrophe's")
  end
  let(:change_request) do
    FactoryGirl.create(
      :update_body_request,
      :public_body => public_body,
      :user => user)
  end

  it "does not add HTMLEntities to the user name" do
    assign(:change_request, change_request)
    render
    expect(response).to match("Test Us'r would like the email address for")
  end

  it "does not add HTMLEntities to the public body name" do
    assign(:change_request, change_request)
    render
    expect(response).to match("email address for Apostrophe's to be updated")
  end
end

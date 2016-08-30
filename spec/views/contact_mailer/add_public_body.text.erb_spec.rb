# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "contact_mailer/add_public_body" do
  let(:user) { FactoryGirl.create(:user, :name => "Test Us'r") }
  let(:change_request) do
    FactoryGirl.create(
      :add_body_request,
      :public_body_name => "Apostrophe's",
      :user => user,
      :notes => "Meeting starts at 12 o'clock")
  end

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
  end

  it "does not add HTMLEntities to the user name" do
    assign(:change_request, change_request)
    render
    expect(response).to match("Test Us'r would like a new authority added")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:change_request, change_request)
    render
    expect(response).to match("new authority added to l'Information")
  end

  it "does not add HTMLEntities to the public body name" do
    assign(:change_request, change_request)
    render
    expect(response).to match("Authority:\nApostrophe's")
  end

end

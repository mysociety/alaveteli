# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "contact_mailer/to_admin_message" do

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
    assign(:message, "hi!")
  end

  it "does not add HTMLEntities to the site name" do
    render
    expect(response).to match("Message sent using l'Information contact form")
  end
end

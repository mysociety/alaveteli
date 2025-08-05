# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "user_mailer/changeemail_already_used" do

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:old_email, "me@here.com")
    assign(:new_email, "nospam@example.com")
    render
    expect(response).to match("the l'Information team")
    expect(response).to match("their email address on l'Information")
  end

  it "does not add HTMLEntities to the email addresses" do
    assign(:old_email, "a'b@example.com")
    assign(:new_email, "c'd@example.com")
    render
    expect(response).
      to match("from a'b@example.com to c'd@example.com")
    expect(response).
      to match("already an account using the email address c'd@example.com")
  end

end

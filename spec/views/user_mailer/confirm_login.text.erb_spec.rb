require 'spec_helper'

RSpec.describe "user_mailer/confirm_login" do

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:reasons, { :email => "nospam@example.com" } )
    render
    expect(response).to match("the l'Information team")
  end

end

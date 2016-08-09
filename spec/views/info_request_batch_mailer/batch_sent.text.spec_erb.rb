# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "info_request_batch_mailer/batch_sent" do
  let(:batch) do
    FactoryGirl.create(
      :info_request_batch,
      :title => "Request apostrophe's data")
  end

  before do
    allow(AlaveteliConfiguration).to receive(:site_name).
      and_return("l'Information")
  end

  it "does not add HTMLEntities to the title" do
    assign(:info_request_batch, batch)
    assign(:unrequestable, [])
    render
    expect(response).
      to match("Your batch request \"Request apostrophe's data\" has been sent")
  end

  it "does not add HTMLEntities to the site name" do
    assign(:info_request_batch, batch)
    assign(:unrequestable, [])
    render
    expect(response).to match("the l'Information team")
  end

  it "does not add HTMLEntities to unrequestable public body names" do
    body_1 = FactoryGirl.create(:public_body, :name => "Dave's Test Authority")
    body_2 = FactoryGirl.create(:public_body, :name => "Jo's Test Authority")
    assign(:info_request_batch, batch)
    assign(:unrequestable, [body_1, body_2])
    render
    expect(response).
      to match("Unfortunately, we do not have a working address for " \
               "Dave's Test Authority, Jo's Test Authority.")
  end
end

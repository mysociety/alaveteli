# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'reports/new.html.erb' do
  let(:info_request) { mock_model(InfoRequest, :url_title => "foo", :report_reasons => ["Weird"]) }
  before :each do
    assign(:info_request, info_request)
  end

  it "should show a form" do
    render
    rendered.should have_selector("form")
  end

  context "request has already been reported" do
    before :each do
      info_request.stub!(:attention_requested).and_return(true)
    end

    it "should not show a form" do
      render
      rendered.should_not have_selector("form")
    end

    it "should say it's already been reported" do
      render
      rendered.should contain("This request has already been reported")
    end
  end
end

# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'reports/new.html.erb' do
  let(:info_request) { FactoryGirl.build(:info_request) }
  before :each do
    assign(:info_request, info_request)
    assign(:report_reasons, info_request.report_reasons)
  end

  it "should show a form" do
    render
    expect(rendered).to have_css("form")
  end

  context "request has already been reported" do
    before :each do
      allow(info_request).to receive(:attention_requested).and_return(true)
    end

    it "should not show a form" do
      render
      expect(rendered).not_to have_css("form")
    end

    it "should say it's already been reported" do
      render
      expect(rendered).to have_content("This request has already been reported")
    end
  end
end

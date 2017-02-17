# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'reports/new.html.erb' do
  let(:info_request) { FactoryGirl.create(:info_request) }
  before :each do
    assign(:info_request, info_request)
    assign(:report_reasons, info_request.report_reasons)
  end

  it "should show a form" do
    render
    expect(rendered).to have_css("form")
  end

  it "has a 'Report request' button" do
    render
    expect(rendered).to have_button("Report request")
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

  context "reporting a comment" do
    let(:comment) do
      FactoryGirl.create(:comment, :info_request => info_request)
    end
    before :each do
      assign(:comment, comment)
      assign(:report_reasons, comment.report_reasons)
    end

    it "has a 'Report annotation' button" do
      render
      expect(rendered).to have_button("Report annotation")
    end

  end
end

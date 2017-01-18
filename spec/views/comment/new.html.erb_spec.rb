# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "comment/new.html.erb" do
  context "when the request is embargoed" do
    let(:info_request) { FactoryGirl.create(:embargoed_request) }

    before do
      assign :info_request, info_request
      render
    end

    it "says the comment will be public when the embargo expires" do
      expected_content = "When your request's embargo expires, any " \
                         "annotations you add will also be public. " \
                         "However, they are not sent " \
                         "to #{info_request.public_body.name}."
      expect(rendered).to have_content(expected_content)
    end

    it "renders the professional comment suggestions" do
      expect(view).to render_template(partial: "alaveteli_pro/comment/_suggestions")
    end
  end

  context "when the request is not embargoed" do
    let(:info_request) { FactoryGirl.create(:info_request) }

    before do
      assign :info_request, info_request
      render
    end

    it "says the comment will be public" do
      expected_content = "Annotations will be posted publicly here, and " \
                         "are not sent to #{info_request.public_body.name}."
      expect(rendered).to have_content(expected_content)
    end

    it "renders the normal comment suggestions" do
      expect(view).to render_template(partial: "comment/_suggestions")
    end
  end
end

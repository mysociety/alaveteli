# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "followups/_followup.html.erb" do
  it "renders the normal title partial when the request is not embargoed" do
    info_request = FactoryGirl.create(:info_request)
    assign :info_request, info_request
    assign :internal_review, false
    assign :outgoing_message, OutgoingMessage.new(info_request: info_request)
    assign :is_owning_user, true
    render partial: "followups/followup", locals: { incoming_message: nil }

    expect(view).to render_template(partial: "followups/_form_title")
  end

  it "renders the pro title partial when the request is embargoed" do
    info_request = FactoryGirl.create(:embargoed_request)
    assign :info_request, info_request
    assign :internal_review, false
    assign :outgoing_message, OutgoingMessage.new(info_request: info_request)
    assign :is_owning_user, true
    render partial: "followups/followup", locals: { incoming_message: nil }

    expect(view).to render_template(partial: "alaveteli_pro/followups/_embargoed_form_title")
  end
end

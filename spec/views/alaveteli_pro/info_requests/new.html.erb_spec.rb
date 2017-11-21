# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "alaveteli_pro/info_requests/new.html.erb" do
  let!(:public_body) { FactoryGirl.create(:public_body) }
  let(:draft_info_request) { FactoryGirl.create(:draft_info_request) }
  let(:info_request) { InfoRequest.from_draft(draft_info_request) }
  let(:outgoing_message) { info_request.outgoing_messages.first }
  let(:embargo) { info_request.embargo }

  def assign_variables
    assign :draft_info_request, draft_info_request
    assign :info_request, info_request
    assign :outgoing_message, outgoing_message
    assign :embargo, embargo
  end

  it "sets a data-initial-authority attribute on the public body search" do
    expected_data = {
      id: public_body.id,
      name: public_body.name,
      short_name: public_body.short_name,
      notes: public_body.notes,
      info_requests_visible_count: public_body.info_requests_visible_count
    }
    expect(view).to receive(:public_body_search_attributes)
      .and_return(expected_data)

    assign_variables
    render

    expected_html = html_escape(expected_data.to_json)
    expect(rendered).to match(/data-initial-authority="#{expected_html}"/)
  end

  it "sets a data-search-url attribute on the public body search" do
    assign_variables
    render
    expect(rendered).to match(/data-search-url="\/alaveteli_pro\/public_bodies"/)
  end

  it "includes a hidden field for the body id" do
    assign_variables
    render
    expected_input = "<input class=\"js-public-body-id\" " \
                     "type=\"hidden\" " \
                     "value=\"#{info_request.public_body.id}\" " \
                     "name=\"info_request\\[public_body_id\\]\" " \
                     "id=\"info_request_public_body_id\" \\/>"

    # Capybara doesn't like matching hidden inputs because users don't see
    # them, hence why we're using a more fragile regex
    expect(rendered).to match(/#{expected_input}/)
  end
end

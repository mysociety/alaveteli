require 'spec_helper'

RSpec.describe "request/details" do
  let(:mock_request) do
    FactoryBot.create(:info_request, title: "Test request")
  end

  it "should show the request" do
    FactoryBot.create(
      :info_request_event,
      event_type: 'edit',
      info_request: mock_request,
      params: {
        "allow_new_responses_from": "nobody",
        "old_allow_new_responses_from": "authority_only"
      }
    )

    assign :info_request, mock_request
    render
    expect(rendered).to have_content('edit metadata')
    expect(rendered).to have_content('allow_new_responses_from')
  end
end

require "spec_helper"

RSpec.describe "Site statistics" do
  before :each do
    allow(AlaveteliConfiguration).to receive(:minimum_requests_for_statistics).
      and_return(1)
    allow(AlaveteliConfiguration).to receive(:public_body_statistics_page).
      and_return(true)
  end

  describe "for public bodies" do
    it "should include all requests except hidden requests in the total count" do
      public_body = FactoryBot.create(:public_body)
      FactoryBot.create(:info_request, public_body: public_body)
      FactoryBot.create(:info_request,
                         public_body: public_body,
                         prominence: "requester_only")
      FactoryBot.create(:info_request,
                         public_body: public_body,
                         described_state: "successful")

      visit "/body_statistics"
      # Find the right table cell
      row = page.all("#info_requests_count-highest tr").find do |tr|
        tr.has_text? public_body.name
      end
      number_of_requests_cell = row.find(".statistic")

      expect(number_of_requests_cell).to have_text "2"
    end
  end
end

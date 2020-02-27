require "spec_helper"

describe "Site statistics" do
  before :each do
    config = MySociety::Config.load_default
    config['MINIMUM_REQUESTS_FOR_STATISTICS'] = 1
    config['PUBLIC_BODY_STATISTICS_PAGE'] = true
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

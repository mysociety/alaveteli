require 'spec_helper'

RSpec.describe "comment/new.html.erb" do
  context "when the request is embargoed" do
    let(:info_request) { FactoryBot.create(:embargoed_request) }
    let(:comment) { info_request.comments.new }
    let(:track_thing) { TrackThing.create_track_for_request(info_request) }

    before do
      assign :info_request, info_request
      assign :comment, comment
      assign :track_thing, track_thing
      assign :in_pro_area, false
      render
    end

    it "says the comment will be public when the embargo expires" do
      expected_content = "When your request is made public on Alaveteli, any " \
                         "annotations you add will also be public. However, they are " \
                         "not sent to #{info_request.public_body.name}."
      expect(rendered).to have_content(expected_content)
    end

    it "renders the professional comment suggestions" do
      expect(view).to render_template(partial: "alaveteli_pro/comment/_suggestions")
    end
  end

  context "when the request is not embargoed" do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:comment) { info_request.comments.new }
    let(:track_thing) { TrackThing.create_track_for_request(info_request) }

    before do
      assign :info_request, info_request
      assign :comment, comment
      assign :track_thing, track_thing
      assign :in_pro_area, true
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

require 'spec_helper'

RSpec.describe "alaveteli_pro/info_request_batches/_authority_list.text.erb" do
  let(:html_body) { FactoryBot.create(:public_body, name: "One & Two") }
  let(:other_body) { FactoryBot.create(:public_body) }
  let(:other_body_2) { FactoryBot.create(:public_body) }
  let(:public_bodies) { [html_body, other_body, other_body_2] }
  let(:template) do
    "alaveteli_pro/info_request_batches/authority_list.text.erb"
  end

  def render_text_partial(public_bodies)
    render partial: template, locals: { public_bodies: public_bodies }
  end

  it "doesn't escape HTMLEntities in public body names" do
    render_text_partial(public_bodies)
    # Note: using include not have_text to test the html entity is not there
    expect(response).to include("One & Two")
    expect(response).not_to include("One &amp; Two")
  end

  context "when there's more than one body" do
    before do
      render_text_partial(public_bodies)
    end

    it "pluralises the message" do
      expected_msg = "3 recipients, including One & Two and " \
                     "#{other_body.name}"
      expect(response).to have_text(expected_msg)
    end
  end

  context "when there's only one body" do
    before do
      render_text_partial([other_body])
    end

    it "singularises the message" do
      expected_msg = "1 recipient, #{other_body.name}"
      expect(response).to have_text(expected_msg)
    end
  end

  context "when there are no bodies" do
    before do
      render_text_partial([])
    end

    it "says there are no bodies" do
      expect(response).to have_text("No bodies selected")
    end
  end
end

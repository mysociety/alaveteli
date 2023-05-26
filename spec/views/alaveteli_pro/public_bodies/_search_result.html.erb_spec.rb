require 'spec_helper'

RSpec.describe 'alaveteli_pro/public_bodies/_search_result' do
  let(:note) { 'Some notes about the body' }

  let(:public_body) do
    FactoryBot.create(:public_body, :with_note,
                      note_body: note,
                      info_requests_visible_count: 1)
  end

  let(:result) do
    {
      name: public_body.name,
      notes: public_body.notes_as_string,
      info_requests_visible_count: public_body.info_requests_visible_count
    }
  end

  def render_view
    render(
      partial: 'alaveteli_pro/public_bodies/search_result',
      locals: { result: result }
    )
  end

  it "includes the body name" do
    render_view
    expect(rendered).to have_text public_body.name
  end

  it "includes the body notes" do
    render_view
    expect(rendered).to have_text public_body.notes_as_string
  end

  context 'long note' do
    let(:note) do
      "This are some extravagantly long notes about a body which will need " \
      "to be trimmed down somewhat before they're suitable for inclusion in " \
      "a small amount of space."
    end

    it "truncates the body notes to 150 chars" do
      render_view
      expected_notes = "This are some extravagantly long notes about a body " \
                       "which will need to be trimmed down somewhat before " \
                       "they're suitable for inclusion in a small am..."
      expect(rendered).not_to have_text public_body.notes_as_string
      expect(rendered).to have_text expected_notes
    end
  end

  it "includes the number of requests made" do
    render_view
    expect(rendered).to have_text("1 request made")
  end

  it "pluralizes the number of requests made" do
    public_body.info_requests_visible_count = 10
    render_view
    expect(rendered).to have_text("10 requests made")
  end
end

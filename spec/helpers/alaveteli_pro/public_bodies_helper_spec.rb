require 'spec_helper'

RSpec.describe AlaveteliPro::PublicBodiesHelper, type: :helper do
  let(:public_body) { FactoryBot.create(:public_body) }

  describe '#public_body_search_attributes' do
    let(:html) { double(:html) }
    let(:notes_as_html) { double(:notes_as_html) }
    let(:expected) do
      {
        id: public_body.id,
        name: public_body.name,
        short_name: public_body.short_name,
        notes: public_body.notes_as_string,
        info_requests_visible_count: public_body.info_requests_visible_count,
        about: _('About {{public_body_name}}',
                 public_body_name: public_body.name),
        html: html,
        notes_as_html: notes_as_html
      }
    end

    before do
      # Stubbing this so we can test both branches of this conditional -
      # In reality from within an view, `render` calls seems to internally uses
      # `render_to_string` but we just can't call it directly
      allow(helper).to receive(:respond_to?).with(:render_to_string).
        and_return(in_controller)
    end

    context 'within a controler' do
      let(:in_controller) { true }

      it 'returns hash with applicable search attribute' do
        expect(helper).to receive(:render_to_string).with(
          hash_including(partial: 'alaveteli_pro/public_bodies/search_result')
        ).and_return(html)

        expect(helper).to receive(:render_to_string).with(
          hash_including(partial: 'alaveteli_pro/public_bodies/notes')
        ).and_return(notes_as_html)

        expect(helper.public_body_search_attributes(public_body)).to eq expected
      end
    end

    context 'within a view' do
      let(:in_controller) { false }

      it 'returns hash with applicable search attribute' do
        expect(helper).to receive(:render).with(
          hash_including(partial: 'alaveteli_pro/public_bodies/search_result')
        ).and_return(html)

        expect(helper).to receive(:render).with(
          hash_including(partial: 'alaveteli_pro/public_bodies/notes')
        ).and_return(notes_as_html)

        expect(helper.public_body_search_attributes(public_body)).to eq expected
      end
    end
  end
end

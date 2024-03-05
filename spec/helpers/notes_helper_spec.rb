require 'spec_helper'

RSpec.describe NotesHelper do
  include NotesHelper

  describe '#note_as_text' do
    subject { note_as_text(note) }

    let(:note) { FactoryBot.build(:note, body: '<h1>title</h1>') }

    it { is_expected.to eq('title') }
  end

  describe '#note_as_html' do
    let(:note) { FactoryBot.build(:note, body: '<h1>title</h1>') }

    context 'when not a batch' do
      subject { note_as_html(note, batch: false) }

      it 'allows more tags' do
        is_expected.to eq('<h1>title</h1>')
      end
    end

    context 'when batch' do
      subject { note_as_html(note, batch: true) }

      it 'removes more tags' do
        is_expected.to eq('title')
      end
    end
  end

  describe '#render_notes' do
    let(:note) { FactoryBot.build(:note, body: '<h1>title</h1>') }

    it 'wrap notes in aside and article tags' do
      expect(self).to receive(:note_as_html).with(note, batch: false).
        and_return('foo')

      expect(render_notes([note], class: 'notes')).to eq(
        '<aside class="notes" id="notes">' \
          '<article id="new_note" class="note note--style-blue tag-some_tag">' \
            'foo' \
          '</article>' \
        '</aside>'
      )
    end

    it 'pass batch argument to note_as_html' do
      expect(self).to receive(:note_as_html).with(note, batch: true).
        and_return('bar')

      expect(render_notes([note], batch: true)).to eq(
        '<aside id="notes">' \
          '<article id="new_note" class="note note--style-blue tag-some_tag">' \
            'bar' \
          '</article>' \
        '</aside>'
      )
    end

    context 'without notes' do
      subject { render_notes([], class: 'notes') }

      it 'renders nothing' do
        is_expected.to be_nil
      end
    end
  end

  describe '#notes_allowed_tags' do
    it 'returns the list of allowed tags' do
      allowed_tags = %w(strong em b i p code pre tt samp kbd var sub sup dfn
                        cite big small address hr br div span h1 h2 h3 h4 h5 h6
                        ul ol li dl dt dd abbr acronym a img blockquote del ins
                        table tr td th u time font iframe)
      expect(notes_allowed_tags).to include(*allowed_tags)
    end
  end

  describe '#batch_notes_allowed_tags' do
    it 'returns the list of allowed tags' do
      allowed_tags = %w(strong em b i p code tt samp kbd var sub sup dfn cite
                        big small address hr br div span ul ol li dl dt dd abbr
                        acronym a del ins table tr td th u time)
      expect(batch_notes_allowed_tags).to include(*allowed_tags)
    end
  end
end

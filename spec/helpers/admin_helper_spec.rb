# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminHelper do

  include AdminHelper
  include ERB::Util

  describe '#comment_visibility' do

    it 'shows the status of a visible comment' do
      comment = FactoryBot.build(:visible_comment)
      expect(comment_visibility(comment)).to eq('Visible')
    end

    it 'shows the status of a hidden comment' do
      comment = FactoryBot.build(:hidden_comment)
      expect(comment_visibility(comment)).to eq('Hidden')
    end

  end

  describe '#sort_order_humanized' do

    it 'returns the humanized value if one is available' do
      expect(sort_order_humanized('name_asc')).to eq('Name ▲')
    end

    it 'returns the titleized value if a humanized value is not available' do
      expect(sort_order_humanized('blah_asc')).to eq('Blah Asc')
    end

    it 'accepts a Symbol argument' do
      expect(sort_order_humanized(:name_asc)).to eq('Name ▲')
    end

  end

  describe '#comment_both_links' do

    let(:comment) { FactoryBot.create(:comment) }

    it 'includes a link to the comment on the site' do
      expect(comment_both_links(comment)).to include(comment_path(comment))
    end

    it 'includes a link to admin edit page for the comment' do
      expect(comment_both_links(comment)).
        to include(edit_admin_comment_path(comment))
    end

  end

  describe '#highlight_allow_new_responses_from' do

    context 'anybody' do
      subject { highlight_allow_new_responses_from('anybody') }

      it 'does not highlight the default case' do
        expect(subject).to eq('anybody')
      end

    end

    context 'authority_only' do
      subject { highlight_allow_new_responses_from('authority_only') }

      it 'adds a warning highlight' do
        expect(subject).
          to eq(%q(<span class="text-warning">authority_only</span>))
      end

    end

    context 'nobody' do
      subject { highlight_allow_new_responses_from('nobody') }

      it 'adds a stronger warning highlight' do
        expect(subject).
          to eq(%q(<span class="text-error">nobody</span>))
      end

    end

    context 'an unhandled string' do
      subject { highlight_allow_new_responses_from('unhandled') }

      it 'does not highlight an unhandled string' do
        expect(subject).to eq('unhandled')
      end

    end

  end

  describe '#highlight_prominence' do

    context 'normal' do
      subject { highlight_prominence('normal') }

      it 'does not highlight the default case' do
        expect(subject).to eq('normal')
      end

    end

    context 'backpage' do
      subject { highlight_prominence('backpage') }

      it 'adds a warning highlight' do
        expect(subject).
          to eq(%q(<span class="text-warning">backpage</span>))
      end

    end

    context 'requester_only' do
      subject { highlight_prominence('requester_only') }

      it 'adds a warning highlight' do
        expect(subject).
          to eq(%q(<span class="text-warning">requester_only</span>))
      end

    end

    context 'hidden' do
      subject { highlight_prominence('hidden') }

      it 'adds a stronger warning highlight' do
        expect(subject).
          to eq(%q(<span class="text-error">hidden</span>))
      end

    end

    context 'an unhandled string' do
      subject { highlight_prominence('unhandled') }

      it 'does not highlight an unhandled string' do
        expect(subject).to eq('unhandled')
      end

    end

  end

end

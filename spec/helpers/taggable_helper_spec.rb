require 'spec_helper'

RSpec.describe TaggableHelper do
  include TaggableHelper

  describe '#tags_css' do
    subject { tags_css(taggable) }

    let(:taggable) { FactoryBot.build(:public_body, tag_string: tag_string) }

    context 'when the taggable has tags' do
      let(:tag_string) { 'foo bar_baz' }
      it { is_expected.to eq('tag--foo tag--bar_baz') }
    end

    context 'when the taggable has tags with values' do
      let(:tag_string) { 'foo bar:baz' }
      it { is_expected.to eq('tag--foo tag--bar') }
    end

    context 'when the taggable has no tags' do
      let(:tag_string) { '' }
      it { is_expected.to be_empty }
    end
  end
end

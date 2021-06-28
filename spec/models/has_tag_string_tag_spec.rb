require 'spec_helper'

RSpec.describe HasTagString::HasTagStringTag do

  class ModelWithTag < ApplicationRecord
    has_tag_string
    after_initialize { self.name ||= 'test' }
  end

  class AnotherModelWithTag < ApplicationRecord
    has_tag_string
    after_initialize { self.name ||= 'test' }
  end

  class GlobalizeModelWithTag < ApplicationRecord
    translates :name
    has_tag_string
    after_initialize { self.name ||= 'test' }
  end

  class CreateModelsWithTags < ActiveRecord::Migration[4.2] # 1.2
    def self.up
      self.verbose = false

      create_table :model_with_tags, force: true do |t|
        t.string :name
        t.timestamps null: false
      end

      create_table :another_model_with_tags, force: true do |t|
        t.string :name
        t.timestamps null: false
      end

      create_table :globalize_model_with_tags, force: true do |t|
        t.timestamps null: false
      end

      create_table :globalize_model_with_tag_translations, force: true do |t|
        t.references 'globalize_model_with_tag',
                     null: false,
                     index: {
                       name: 'index_globalize_tagged_translations_with_tag_id'
                     }
        t.string :locale, null: false
        t.string :name
        t.timestamps null: false
      end

    end

    def self.down
      self.verbose = false
      drop_table :model_with_tags, force: true
      drop_table :another_model_with_tags, force: true
    end
  end

  before(:all) do
    CreateModelsWithTags.up
  end

  after(:all) do
    CreateModelsWithTags.down
  end

  describe '.find_by_tag' do
    subject { ModelWithTag.find_by_tag('test') }

    context 'when a record with the tag does not exist' do
      let!(:model_1) { ModelWithTag.create(tag_string: 'foo') }
      it { is_expected.to be_empty }
    end

    context 'when a record with the tag exists' do
      let!(:model_1) { ModelWithTag.create(tag_string: 'test') }
      it { is_expected.to match_array([model_1]) }
    end

    context 'when a record with several tags exists' do
      let!(:model_1) { ModelWithTag.create(tag_string: 'foo test') }
      it { is_expected.to match_array([model_1]) }
    end

    context 'when several records with the tag exist' do
      let!(:model_1) { ModelWithTag.create(tag_string: 'test') }
      let!(:model_2) { ModelWithTag.create(tag_string: 'test') }
      let!(:model_3) { ModelWithTag.create(tag_string: 'foo test') }
      it { is_expected.to match_array([model_1, model_2, model_3]) }
    end

    context 'sorting the results' do
      let!(:model_1) { ModelWithTag.create(name: 'b', tag_string: 'test') }
      let!(:model_2) { ModelWithTag.create(name: 'c', tag_string: 'test') }
      let!(:model_3) { ModelWithTag.create(name: 'a', tag_string: 'foo test') }

      it 'sorts by name ASC' do
        expect(subject).to match([model_3, model_1, model_2])
      end
    end

    context 'when a model gets tagged twice with the same tag' do
      let!(:model_1) { ModelWithTag.create(tag_string: 'test test') }

      it 'does not return two instances' do
        expect(subject).to match_array([model_1])
      end
    end

    context 'when a different model with the tag exists' do
      let!(:model_1) { AnotherModelWithTag.create(tag_string: 'test') }
      it { is_expected.to be_empty }
    end

    context 'when a different model with a different tag exists' do
      let!(:model_1) { AnotherModelWithTag.create(tag_string: 'foo') }
      it { is_expected.to be_empty }
    end

    context 'when several records with the tag exist' do
      let!(:model_1) { ModelWithTag.create(tag_string: 'test') }
      let!(:model_2) { ModelWithTag.create(tag_string: 'foo test') }
      let!(:model_3) { AnotherModelWithTag.create(tag_string: 'test') }
      let!(:model_4) { AnotherModelWithTag.create(tag_string: 'foo test') }
      it { is_expected.to match_array([model_1, model_2]) }
    end

    context 'when several translated records with the tag exist' do
      let!(:model_1) { GlobalizeModelWithTag.create(name: 'b', tag_string: 'test') }
      let!(:model_2) { GlobalizeModelWithTag.create(name: 'c', tag_string: 'test') }
      let!(:model_3) { GlobalizeModelWithTag.create(name: 'a', tag_string: 'foo test') }

      it 'sorts by name ASC' do
        subject = GlobalizeModelWithTag.find_by_tag('test')
        expect(subject).to match([model_3, model_1, model_2])
      end
    end

  end

  describe '#add_tag_if_not_already_present' do
    subject { model.add_tag_if_not_already_present(tag) }

    let!(:model) { ModelWithTag.create(tag_string: 'foo testing') }

    context 'when the tag is already present' do
      let(:tag) { 'foo' }
      it { is_expected.to eq('foo testing') }
    end

    context 'when a similar tag is already present' do
      let(:tag) { 'test' }
      it { is_expected.to eq('foo testing test') }
    end

    context 'when the tag is not present' do
      let(:tag) { 'bar' }
      it { is_expected.to eq('foo testing bar') }
    end
  end
end

RSpec.describe HasTagString::HasTagStringTag, " when fiddling with tag strings" do

  it "should be able to make a new tag and save it" do
    @tag = HasTagString::HasTagStringTag.new
    @tag.model = 'PublicBody'
    @tag.model_id = public_bodies(:geraldine_public_body).id
    @tag.name = "moo"
    @tag.save
  end

end

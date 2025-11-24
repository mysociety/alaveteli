RSpec.shared_examples 'concerns/taggable' do |factory_opts|
  let(:record) { FactoryBot.create(*factory_opts) }

  describe '.with_tag' do
    it 'should return objects with key/value tags' do
      record.tag_string = 'eats_cheese:stilton'

      scope = described_class.with_tag('eats_cheese')
      expect(scope).to match_array([record])

      scope = described_class.with_tag('eats_cheese:jarlsberg')
      expect(scope).to be_empty

      scope = described_class.with_tag('eats_cheese:stilton')
      expect(scope).to match_array([record])
    end

    it 'should return objects with tags' do
      record.tag_string = 'mycategory'
      record.reload

      scope = described_class.with_tag('mycategory')
      expect(scope).to match_array([record])

      scope = described_class.with_tag('myothercategory')
      expect(scope).to be_empty
    end
  end

  describe '.without_tag' do
    it 'should not return objects with key/value tags' do
      record.tag_string = 'eats_cheese:stilton'

      scope = described_class.without_tag('eats_cheese')
      expect(scope).to_not include(record)

      scope = described_class.without_tag('eats_cheese:stilton')
      expect(scope).to_not include(record)

      scope = described_class.without_tag('eats_cheese:jarlsberg')
      expect(scope).to include(record)
    end

    it 'should not return objects with tags' do
      record.tag_string = 'mycategory'

      scope = described_class.without_tag('mycategory')
      expect(scope).to_not include(record)

      scope = described_class.without_tag('myothercategory')
      expect(scope).to include(record)
    end

    it 'should be chainable to exclude more than one tag' do
      record.tag_string = 'defunct'
      record_2 = FactoryBot.create(*factory_opts, tag_string: 'council')
      record_3 = FactoryBot.create(*factory_opts, tag_string: 'not_apply')

      scope = described_class.without_tag('defunct').without_tag('not_apply')
      expect(scope).to include(record_2)
      expect(scope).to_not include(record)
      expect(scope).to_not include(record_3)
    end
  end
end

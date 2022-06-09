RSpec.shared_examples 'concerns/taggable' do
  describe '.with_tag' do
    let(:instance_1) { FactoryBot.create(base_factory) }

    it 'should return objects with key/value tags' do
      instance_1.tag_string = 'eats_cheese:stilton'

      scope = described_class.with_tag('eats_cheese')
      expect(scope).to match_array([instance_1])

      scope = described_class.with_tag('eats_cheese:jarlsberg')
      expect(scope).to be_empty

      scope = described_class.with_tag('eats_cheese:stilton')
      expect(scope).to match_array([instance_1])
    end

    it 'should return objects with tags' do
      instance_1.tag_string = 'mycategory'

      scope = described_class.with_tag('mycategory')
      expect(scope).to match_array([instance_1])

      scope = described_class.with_tag('myothercategory')
      expect(scope).to be_empty
    end
  end

  describe '.without_tag' do
    let(:instance_1) { FactoryBot.create(base_factory) }

    it 'should not return objects with key/value tags' do
      instance_1.tag_string = 'eats_cheese:stilton'

      scope = described_class.without_tag('eats_cheese')
      expect(scope).to_not include(instance_1)

      scope = described_class.without_tag('eats_cheese:stilton')
      expect(scope).to_not include(instance_1)

      scope = described_class.without_tag('eats_cheese:jarlsberg')
      expect(scope).to include(instance_1)
    end

    it 'should not return objects with tags' do
      instance_1.tag_string = 'mycategory'

      scope = described_class.without_tag('mycategory')
      expect(scope).to_not include(instance_1)

      scope = described_class.without_tag('myothercategory')
      expect(scope).to include(instance_1)
    end

    it 'should be chainable to exclude more than one tag' do
      instance_1.tag_string = 'defunct'
      instance_2 = FactoryBot.create(base_factory, tag_string: 'council')
      instance_3 = FactoryBot.create(base_factory, tag_string: 'not_apply')

      scope = described_class.without_tag('defunct').without_tag('not_apply')
      expect(scope).to include(instance_2)
      expect(scope).to_not include(instance_1)
      expect(scope).to_not include(instance_3)
    end
  end
end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyHelper do
  include PublicBodyHelper

  describe '#public_body_not_requestable_reasons' do

    before do
      @body = FactoryGirl.build(:public_body)
    end

    it 'returns an empty array if there are no reasons' do
      expect(public_body_not_requestable_reasons(@body)).to eq([])
    end

    it 'includes a reason if the law does not apply to the authority' do
      @body.tag_string = 'not_apply'
      msg = 'Freedom of Information law does not apply to this authority, so you cannot make a request to it.'
      expect(public_body_not_requestable_reasons(@body)).to include(msg)
    end

    it 'includes a reason if the body no longer exists' do
      @body.tag_string = 'defunct'
      msg = 'This authority no longer exists, so you cannot make a request to it.'
      expect(public_body_not_requestable_reasons(@body)).to include(msg)
    end

    it 'links to the request page if the body has no contact email' do
      @body.request_email = ''
      msg = %Q(<a href="/new/#{ @body.url_name }"
               class="link_button_green">Make
               a request to this authority</a>).squish

               expect(public_body_not_requestable_reasons(@body)).to include(msg)
    end

    it 'returns the reasons in order of importance' do
      @body.tag_string = 'defunct not_apply'
      @body.request_email = ''

      reasons = public_body_not_requestable_reasons(@body)

      expect(reasons[0]).to match(/no longer exists/)
      expect(reasons[1]).to match(/does not apply/)
      expect(reasons[2]).to match(/Make a request/)
    end

  end


  describe '#type_of_authority' do

    it 'falls back to "A public authority"' do
      public_body = FactoryGirl.build(:public_body)
      expect(type_of_authority(public_body)).to eq('A public authority')
    end

    it 'handles Unicode' do
      category = FactoryGirl.create(:public_body_category, :category_tag => 'spec',
                                    :description => 'ünicode category')
      heading = FactoryGirl.create(:public_body_heading)
      heading.add_category(category)
      public_body = FactoryGirl.create(:public_body, :tag_string => 'spec')


      expect(type_of_authority(public_body)).to eq('<a href="/body/list/spec">Ünicode category</a>')
    end

    it 'constructs the correct string if there are tags which are not categories' do
      heading = FactoryGirl.create(:public_body_heading)
      3.times do |i|
        category = FactoryGirl.create(:public_body_category, :category_tag => "spec_#{i}",
                                      :description => "spec category #{i}")
        heading.add_category(category)
      end
      public_body = FactoryGirl.create(:public_body, :tag_string => 'unknown spec_0 spec_2')
      expected = '<a href="/body/list/spec_0">Spec category 0</a> and <a href="/body/list/spec_2">spec category 2</a>'
      expect(type_of_authority(public_body)).to eq(expected)
    end


    context 'when associated with one category' do

      it 'returns the description wrapped in an anchor tag' do
        category = FactoryGirl.create(:public_body_category, :category_tag => 'spec',
                                      :description => 'spec category')
        heading = FactoryGirl.create(:public_body_heading)
        heading.add_category(category)
        public_body = FactoryGirl.create(:public_body, :tag_string => 'spec')

        anchor = %Q(<a href="/body/list/spec">Spec category</a>)
        expect(type_of_authority(public_body)).to eq(anchor)
      end
    end

    context 'when associated with several categories' do

      it 'joins the category descriptions and capitalizes the first letter' do
        heading = FactoryGirl.create(:public_body_heading)
        3.times do |i|
          category = FactoryGirl.create(:public_body_category, :category_tag => "spec_#{i}",
                                        :description => "spec category #{i}")
          heading.add_category(category)
        end
        public_body = FactoryGirl.create(:public_body, :tag_string => 'spec_0 spec_1 spec_2')

        description = [
          %Q(<a href="/body/list/spec_0">Spec category 0</a>),
          ', ',
          %Q(<a href="/body/list/spec_1">spec category 1</a>),
          ' and ',
          %Q(<a href="/body/list/spec_2">spec category 2</a>)
        ].join('')

        expect(type_of_authority(public_body)).to eq(description)
      end

    end

    context 'when in a non-default locale' do

      it 'creates the anchor href in the correct locale' do
        # Activate the routing filter, normally turned off for helper tests
        RoutingFilter.active = true
        category = FactoryGirl.create(:public_body_category, :category_tag => 'spec',
                                      :description => 'spec category')
        heading = FactoryGirl.create(:public_body_heading)
        heading.add_category(category)
        public_body = FactoryGirl.create(:public_body, :tag_string => 'spec')

        anchor = %Q(<a href="/es/body/list/spec">Spec category</a>)
        I18n.with_locale(:es) { expect(type_of_authority(public_body)
                                      ).to eq(anchor) }
      end

    end

  end

end

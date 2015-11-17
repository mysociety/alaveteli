# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe TranslatableParams do
  include TranslatableParams

  describe '#translatable_params' do

    let(:keys) { { :translated_keys => [ :name, :locale ],
                   :general_keys => [ :status ] } }

    it 'whitelists translatable_params' do
      params = { :name => 'Some name',
                 :status => 'good',
                 :id => 40,
                 :translations_attributes =>
                  { :en =>
                    { :locale => 'en',
                      :name => 'Other name',
                      :bad => "value" } } }
      expected = { :name => 'Some name',
                   :status => 'good',
                   :translations_attributes =>
                    { :en =>
                      { :locale => 'en',
                        :name => 'Other name' } } }
      expect(translatable_params(keys, params)).
        to eq(expected)
    end

  end

end

describe TranslatableParams::WhitelistedParams do

  describe '#whitelist' do

    let(:keys) { { :translated_keys => [ :name, :locale ],
                   :general_keys => [ :status ] } }

    it 'removes a non-whitelisted model param' do
      params = { :name => 'Some name',
                 :status => 'good',
                 :id => 40 }
      expected = { :name => 'Some name',
                   :status => 'good' }
      expect(TranslatableParams::WhitelistedParams.new(keys).whitelist(params))
        .to eq(expected)
    end

    it 'allows id in the translation params' do
      params = { :translations_attributes =>
                 { :en =>
                   { :id => 40,
                     :locale => 'en',
                     :name => 'Other name' } } }
      expect(TranslatableParams::WhitelistedParams.new(keys).whitelist(params.dup))
        .to eq(params)
    end

    it 'removes a non-whitelisted translation param' do
      params = { :translations_attributes =>
                 { :en =>
                   { :locale => 'en',
                     :name => 'Other name',
                     :bad => "value" } } }
      expected = { :translations_attributes =>
                   { :en =>
                    { :locale => 'en',
                      :name => 'Other name'} } }
      expect(TranslatableParams::WhitelistedParams.new(keys).whitelist(params))
        .to eq(expected)
    end

  end

end

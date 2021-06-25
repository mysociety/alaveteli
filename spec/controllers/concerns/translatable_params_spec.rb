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

      params = ActionController::Parameters.new(params)
      expect(translatable_params(params, keys)).
        to eq(ActionController::Parameters.new(expected).permit!)
    end

    context 'when there are no params' do

      it 'returns an empty hash' do
        expect(translatable_params(nil, keys)).to eq({})
      end

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

      params = ActionController::Parameters.new(params)
      expect(TranslatableParams::WhitelistedParams.new(keys).whitelist(params)).
        to eq(ActionController::Parameters.new(expected).permit!)
    end

    it 'allows id in the translation params' do
      params = { :translations_attributes =>
                 { :en =>
                   { :id => 40,
                     :locale => 'en',
                     :name => 'Other name' } } }
      expected = ActionController::Parameters.new(params).permit!

      params = params = ActionController::Parameters.new(params)
      expect(TranslatableParams::WhitelistedParams.new(keys).whitelist(params.dup)).
        to eq(expected)
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
                      :name => 'Other name' } } }

      params = ActionController::Parameters.new(params)
      expect(TranslatableParams::WhitelistedParams.new(keys).whitelist(params)).
        to eq(ActionController::Parameters.new(expected).permit!)
    end

  end

end

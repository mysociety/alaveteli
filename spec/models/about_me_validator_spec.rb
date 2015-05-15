# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AboutMeValidator do

  describe :new do

    it 'sets each supported attribute on the instance' do
      params = { :about_me => 'My description' }
      validator = AboutMeValidator.new(params)
      expect(validator.about_me).to eq('My description')
    end

  end

  describe :valid? do

    it 'is valid if about_me is =< 500' do
      params = { :about_me => 'a'*500 }
      validator = AboutMeValidator.new(params)
      expect(validator).to be_valid
    end

    it 'is valid if about_me is blank' do
      params = { :about_me => '' }
      validator = AboutMeValidator.new(params)
      expect(validator).to be_valid
    end

    it 'is valid if about_me is nil' do
      params = { :about_me => nil }
      validator = AboutMeValidator.new(params)
      expect(validator).to be_valid
    end

    it 'is invalid if about_me is > 500' do
      params = { :about_me => 'a'*501 }
      validator = AboutMeValidator.new(params)
      expect(validator).to have(1).error_on(:about_me)
    end

  end

  describe :about_me do

    it 'has an attribute accessor' do
      params = { :about_me => 'My description' }
      validator = AboutMeValidator.new(params)
      expect(validator.about_me).to eq('My description')
    end

  end

end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContactValidator do

  describe '.new' do

    let(:valid_params) do
      { :name => "Vinny Vanilli",
        :email => "vinny@localhost",
        :subject => "Why do I have such an ace name?",
        :message => "You really should know!!!\n\nVinny" }
    end

    it 'validates specified attributes' do
      expect(ContactValidator.new(valid_params)).to be_valid
    end

    it 'validates name is present' do
      valid_params.except!(:name)
      validator = ContactValidator.new(valid_params)
      validator.valid?
      expect(validator.errors[:name].size).to eq(1)
    end

    it 'validates email is present' do
      valid_params.except!(:email)
      validator = ContactValidator.new(valid_params)
      # We have 2 errors on email because of the format validator
      validator.valid?
      expect(validator.errors[:email].size).to eq(2)
    end

    it 'validates email format' do
      valid_params.merge!({:email => 'not-an-email'})
      validator = ContactValidator.new(valid_params)
      validator.valid?
      expect(validator.errors[:email]).to include("Email doesn't look like a valid address")
    end

    it 'validates subject is present' do
      valid_params.except!(:subject)
      validator = ContactValidator.new(valid_params)
      validator.valid?
      expect(validator.errors[:subject].size).to eq(1)
    end

    it 'validates message is present' do
      valid_params.except!(:message)
      validator = ContactValidator.new(valid_params)
      validator.valid?
      expect(validator.errors[:message].size).to eq(1)
    end

  end

end

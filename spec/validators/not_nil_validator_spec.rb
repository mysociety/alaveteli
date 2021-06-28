require 'spec_helper'

class Validatable
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :subject_attr

  validates :subject_attr, :not_nil => true
end

class ValidatableCustomMessage
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :subject_attr

  validates :subject_attr, :not_nil => { :message => 'Custom message' }
end

describe NotNilValidator do

  it 'is valid when the subject_attr is not blank' do
    subject = Validatable.new(:subject_attr => 'xyz')
    expect(subject).to be_valid
  end

  it 'is valid when the subject_attr is blank' do
    subject = Validatable.new(:subject_attr => '')
    expect(subject).to be_valid
  end

  it 'is invalid when the subject_attr is nil' do
    subject = Validatable.new(:subject_attr => nil)
    expect(subject).to_not be_valid
  end

  it 'sets a default error message' do
    subject = Validatable.new(:subject_attr => nil)
    subject.valid?
    expect(subject.errors[:subject_attr]).to eq(["can't be nil"])
  end

  it 'supports a custom error message' do
    subject = ValidatableCustomMessage.new(:subject_attr => nil)
    subject.valid?
    expect(subject.errors[:subject_attr]).to eq(['Custom message'])
  end

end

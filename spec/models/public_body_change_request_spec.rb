# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_change_requests
#
#  id                :integer          not null, primary key
#  user_email        :string(255)
#  user_name         :string(255)
#  user_id           :integer
#  public_body_name  :text
#  public_body_id    :integer
#  public_body_email :string(255)
#  source_url        :text
#  notes             :text
#  is_open           :boolean          default(TRUE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyChangeRequest, 'when validating' do

  it 'should not be valid without a public body name' do
    change_request = PublicBodyChangeRequest.new
    expect(change_request.valid?).to be false
    expect(change_request.errors[:public_body_name]).to eq(['Please enter the name of the authority'])
  end

  it 'should not be valid without a user name if there is no user' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body')
    expect(change_request.valid?).to be false
    expect(change_request.errors[:user_name]).to eq(['Please enter your name'])
  end

  it 'should not be valid without a user email address if there is no user' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body')
    expect(change_request.valid?).to be false
    expect(change_request.errors[:user_email]).to eq(['Please enter your email address'])
  end

  it 'should be valid with a user and no name or email address' do
    user = FactoryGirl.build(:user)
    change_request = PublicBodyChangeRequest.new(:user => user,
                                                 :public_body_name => 'New Body')
    expect(change_request.valid?).to be true
  end

  it 'should validate the format of a user email address entered' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body',
                                                 :user_email => '@example.com')
    expect(change_request.valid?).to be false
    expect(change_request.errors[:user_email]).to eq(["Your email doesn't look like a valid address"])
  end

  it 'should validate the format of a public body email address entered' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body',
                                                 :public_body_email => '@example.com')
    expect(change_request.valid?).to be false
    expect(change_request.errors[:public_body_email]).to eq(["The authority email doesn't look like a valid address"])
  end

end

describe PublicBodyChangeRequest, 'get_user_name' do

  it 'should return the user_name field if there is no user association' do
    change_request = PublicBodyChangeRequest.new(:user_name => 'Test User')
    expect(change_request.get_user_name).to eq('Test User')
  end

  it 'should return the name of the associated user if there is one' do
    user = FactoryGirl.build(:user)
    change_request = PublicBodyChangeRequest.new(:user => user)
    expect(change_request.get_user_name).to eq(user.name)
  end

end


describe PublicBodyChangeRequest, 'get_user_email' do

  it 'should return the user_email field if there is no user association' do
    change_request = PublicBodyChangeRequest.new(:user_email => 'user@example.com')
    expect(change_request.get_user_email).to eq('user@example.com')
  end

  it 'should return the email of the associated user if there is one' do
    user = FactoryGirl.build(:user)
    change_request = PublicBodyChangeRequest.new(:user => user)
    expect(change_request.get_user_email).to eq(user.email)
  end

end


describe PublicBodyChangeRequest, 'get_public_body_name' do

  it 'should return the public_body_name field if there is no public body association' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'Test Authority')
    expect(change_request.get_public_body_name).to eq('Test Authority')
  end

  it 'should return the name of the associated public body if there is one' do
    public_body = FactoryGirl.build(:public_body)
    change_request = PublicBodyChangeRequest.new(:public_body => public_body)
    expect(change_request.get_public_body_name).to eq(public_body.name)
  end

end

describe PublicBodyChangeRequest, 'when creating a comment for the associated public body' do

  it 'should include requesting user, source_url and notes' do
    change_request = PublicBodyChangeRequest.new(:user_name => 'Test User',
                                                 :user_email => 'test@example.com',
                                                 :source_url => 'http://www.example.com',
                                                 :notes => 'Some notes')
    expected = "Requested by: Test User (test@example.com)\nSource URL: http://www.example.com\nNotes: Some notes"
    expect(change_request.comment_for_public_body).to eq(expected)
  end

end

describe PublicBodyChangeRequest, 'when creating a default subject for a response email' do

  it 'should create an appropriate subject for a request to add a body' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'Test Body')
    expect(change_request.default_response_subject).to eq('Your request to add Test Body to Alaveteli')
  end

  it 'should create an appropriate subject for a request to update an email address' do
    public_body = FactoryGirl.build(:public_body)
    change_request = PublicBodyChangeRequest.new(:public_body => public_body)
    expect(change_request.default_response_subject).to eq("Your request to update #{public_body.name} on Alaveteli")

  end

end

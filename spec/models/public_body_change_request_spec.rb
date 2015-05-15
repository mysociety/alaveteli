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
        change_request = PublicBodyChangeRequest.new()
        change_request.valid?.should be_false
        change_request.errors[:public_body_name].should == ['Please enter the name of the authority']
    end

    it 'should not be valid without a user name if there is no user' do
        change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body')
        change_request.valid?.should be_false
        change_request.errors[:user_name].should == ['Please enter your name']
    end

    it 'should not be valid without a user email address if there is no user' do
        change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body')
        change_request.valid?.should be_false
        change_request.errors[:user_email].should == ['Please enter your email address']
    end

    it 'should be valid with a user and no name or email address' do
        user = FactoryGirl.build(:user)
        change_request = PublicBodyChangeRequest.new(:user => user,
                                                     :public_body_name => 'New Body')
        change_request.valid?.should be_true
    end

    it 'should validate the format of a user email address entered' do
        change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body',
                                                     :user_email => '@example.com')
        change_request.valid?.should be_false
        change_request.errors[:user_email].should == ["Your email doesn't look like a valid address"]
    end

    it 'should validate the format of a public body email address entered' do
        change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body',
                                                    :public_body_email => '@example.com')
        change_request.valid?.should be_false
        change_request.errors[:public_body_email].should == ["The authority email doesn't look like a valid address"]
    end

end

describe PublicBodyChangeRequest, 'get_user_name' do

    it 'should return the user_name field if there is no user association' do
        change_request = PublicBodyChangeRequest.new(:user_name => 'Test User')
        change_request.get_user_name.should == 'Test User'
    end

    it 'should return the name of the associated user if there is one' do
        user = FactoryGirl.build(:user)
        change_request = PublicBodyChangeRequest.new(:user => user)
        change_request.get_user_name.should == user.name
    end

end


describe PublicBodyChangeRequest, 'get_user_email' do

    it 'should return the user_email field if there is no user association' do
        change_request = PublicBodyChangeRequest.new(:user_email => 'user@example.com')
        change_request.get_user_email.should == 'user@example.com'
    end

    it 'should return the email of the associated user if there is one' do
        user = FactoryGirl.build(:user)
        change_request = PublicBodyChangeRequest.new(:user => user)
        change_request.get_user_email.should == user.email
    end

end


describe PublicBodyChangeRequest, 'get_public_body_name' do

    it 'should return the public_body_name field if there is no public body association' do
        change_request = PublicBodyChangeRequest.new(:public_body_name => 'Test Authority')
        change_request.get_public_body_name.should == 'Test Authority'
    end

    it 'should return the name of the associated public body if there is one' do
        public_body = FactoryGirl.build(:public_body)
        change_request = PublicBodyChangeRequest.new(:public_body => public_body)
        change_request.get_public_body_name.should == public_body.name
    end

end

describe PublicBodyChangeRequest, 'when creating a comment for the associated public body' do

    it 'should include requesting user, source_url and notes' do
        change_request = PublicBodyChangeRequest.new(:user_name => 'Test User',
                                                     :user_email => 'test@example.com',
                                                     :source_url => 'http://www.example.com',
                                                     :notes => 'Some notes')
        expected = "Requested by: Test User (test@example.com)\nSource URL: http://www.example.com\nNotes: Some notes"
        change_request.comment_for_public_body.should == expected
    end

end

describe PublicBodyChangeRequest, 'when creating a default subject for a response email' do

    it 'should create an appropriate subject for a request to add a body' do
        change_request = PublicBodyChangeRequest.new(:public_body_name => 'Test Body')
        change_request.default_response_subject.should == 'Your request to add Test Body to Alaveteli'
    end

    it 'should create an appropriate subject for a request to update an email address' do
        public_body = FactoryGirl.build(:public_body)
        change_request = PublicBodyChangeRequest.new(:public_body => public_body)
        change_request.default_response_subject.should == "Your request to update #{public_body.name} on Alaveteli"

    end

end


# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequestBatchMailer do

  describe 'when sending batch sent notification' do

    before do
      @user = FactoryGirl.create(:user)
      @info_request_batch = FactoryGirl.create(:info_request_batch)
      @public_body = FactoryGirl.create(:public_body)
      @unrequestable = [@public_body]
      @mail = InfoRequestBatchMailer.batch_sent(@info_request_batch, @unrequestable, @user)
    end

    it 'renders the subject' do
      @mail.subject.should == 'Your batch request "Example title" has been sent'
    end

    it 'renders the receiver email' do
      @mail.to.should == [@user.email]
    end

    it 'renders the sender email' do
      @mail.from.should == ['postmaster@localhost']
    end

    it 'assigns @unrequestable' do
      @mail.body.encoded.should match(@public_body.name)
    end

    it 'assigns @url' do
      @mail.body.encoded.should match("http://test.host/en/c/")
    end
  end
end

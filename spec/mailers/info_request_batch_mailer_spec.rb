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
      expect(@mail.subject).to eq('Your batch request "Example title" has been sent')
    end

    it "does not add HTMLEntities to the subject line" do
      batch = FactoryGirl.create(:info_request_batch, :title => "Apostrophe's")
      mail = InfoRequestBatchMailer.batch_sent(batch, @unrequestable, @user)
      expect(mail.subject).
        to eq('Your batch request "Apostrophe\'s" has been sent')
    end

    it 'renders the receiver email' do
      expect(@mail.to).to eq([@user.email])
    end

    it 'renders the sender email' do
      expect(@mail.from).to eq(['postmaster@localhost'])
    end

    it 'assigns @unrequestable' do
      expect(@mail.body.encoded).to match(@public_body.name)
    end

    it 'assigns @url' do
      expect(@mail.body.encoded).to match("http://test.host/en/c/")
    end
  end
end

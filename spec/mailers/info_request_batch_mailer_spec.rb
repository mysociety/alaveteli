require 'spec_helper'

RSpec.describe InfoRequestBatchMailer do
  describe 'when sending batch sent notification' do
    before do
      @user = FactoryBot.create(:user)
      @info_request_batch = FactoryBot.create(
        :info_request_batch, title: 'Example title'
      )
      @public_body = FactoryBot.create(:public_body)
      @unrequestable = [@public_body]
      @mail = InfoRequestBatchMailer.batch_sent(@info_request_batch, @unrequestable, @user)
    end

    it 'renders the subject' do
      expect(@mail.subject).to eq('Your batch request "Example title" has been sent')
    end

    it "does not add HTMLEntities to the subject line" do
      batch = FactoryBot.create(:info_request_batch, title: "Apostrophe's")
      mail = InfoRequestBatchMailer.batch_sent(batch, @unrequestable, @user)
      expect(mail.subject).
        to eq('Your batch request "Apostrophe\'s" has been sent')
    end

    context "when the user does not use default locale" do
      before do
        @user.locale = 'es'
        @mail = InfoRequestBatchMailer.batch_sent(
          @info_request_batch,
          @unrequestable,
          @user
        )
      end

      it "translates the subject" do
        expect(@mail.subject).
          to eq "Tu solicitud en lote \"Example title\" ha sido enviada"
      end
    end

    it 'renders the receiver email' do
      expect(@mail.to).to eq([@user.email])
    end

    it 'renders the sender email' do
      expect(@mail.from).to eq([blackhole_email])
    end

    it 'assigns @unrequestable' do
      expect(@mail.body.encoded).to match(@public_body.name)
    end

    it 'assigns @url' do
      @mail.body.to_s =~ /(http:\/\/.*)/
      mail_url = $1
      expect(mail_url).to eq(info_request_batch_url(@info_request_batch))
    end
  end
end

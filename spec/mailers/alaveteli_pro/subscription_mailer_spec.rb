require 'spec_helper'

RSpec.describe AlaveteliPro::SubscriptionMailer, feature: [:alaveteli_pro] do
  describe '.payment_failed' do
    let(:user) { FactoryBot.create(:pro_user, name: 'Paul Pro') }
    subject { described_class.payment_failed(user) }

    it 'sets an appropriate subject' do
      expect(subject.subject).
        to eq('Action Required: Payment failed on Alaveteli Professional')
    end

    it 'notifies the given user' do
      expect(subject.to).to include(user.email)
    end

    it 'renders the body correctly' do
      content = ::Mail::Utilities.to_crlf(
        read_described_class_fixture('payment_failed')
      )
      expect(subject.body.to_s).to eq(content)
    end

    context 'with non-html-safe characters in the site name' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:pro_site_name).and_return('&laveteli Pro')
      end

      it 'does not escape characters in the site name' do
        expect(subject.body.to_s).not_to match(/&amp;laveteli Pro/)
      end
    end

    context "when the user does not use default locale" do
      before do
        user.locale = 'es'
      end

      it "translates the subject" do
        expect(subject.subject).
          to eq "*** Spanish missing *** Alaveteli Professional"
      end
    end
  end
end

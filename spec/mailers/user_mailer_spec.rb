require 'spec_helper'

RSpec.describe UserMailer do
  describe '#confirm_login' do
    let(:user) { FactoryBot.create(:user, locale: 'es') }

    it 'renders the subject in the recipient locale' do
      mail = described_class.
        confirm_login(user, { email: '' }, 'http://localhost/c/abc')

      expect(mail.subject).to eq('Confirma tu cuenta en Alaveteli')
    end
  end
end

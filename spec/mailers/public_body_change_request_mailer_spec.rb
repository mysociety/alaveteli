require 'spec_helper'

RSpec.describe PublicBodyChangeRequestMailer do
  shared_examples_for 'PublicBodyChangeRequestMailer' do
    it 'sets the Reply-To header to the change request user' do
      expect(subject['Reply-To'].value).to include('Jim <jim@localhost>')
    end

    it 'sets the from address to the blackhole email' do
      expect(subject['From'].value).
        to include('Jim <do-not-reply-to-this-address@localhost>')
    end

    it 'sends the mail to the admin team' do
      expect(subject['To'].value).
        to include('Alaveteli Webmaster <postmaster@localhost>')
    end
  end

  let(:user) { FactoryBot.create(:user, name: 'Jim', email: 'jim@localhost') }

  describe '.add_public_body' do
    subject { described_class.add_public_body(change_request) }

    let(:change_request) do
      FactoryBot.create(:add_body_request,
                        user: user,
                        public_body_name: "Apostrophe's")
    end

    it 'sets the subject' do
      expect(subject.subject).to eq("Add authority - Apostrophe's")
    end

    it 'uses the add_public_body template' do
      expect(subject.body.to_s).to match(/would like a new authority added to/)
    end

    it_behaves_like 'PublicBodyChangeRequestMailer'
  end

  describe '.update_public_body' do
    subject { described_class.update_public_body(change_request) }
    let(:public_body) { FactoryBot.create(:public_body, name: "Apostrophe's") }

    let(:change_request) do
      FactoryBot.create(:update_body_request, user: user,
                                              public_body: public_body)
    end

    it 'sets the subject' do
      expect(subject.subject).to eq("Update email address - Apostrophe's")
    end

    it 'uses the update_public_body template' do
      expect(subject.body.to_s).to match(/would like the email address for/)
    end

    it_behaves_like 'PublicBodyChangeRequestMailer'
  end
end

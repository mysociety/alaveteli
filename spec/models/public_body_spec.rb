# == Schema Information
# Schema version: 20220210114052
#
# Table name: public_bodies
#
#  id                                     :integer          not null, primary key
#  version                                :integer          not null
#  last_edit_editor                       :string           not null
#  last_edit_comment                      :text
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  home_page                              :text
#  api_key                                :string           not null
#  info_requests_count                    :integer          default(0), not null
#  disclosure_log                         :text
#  info_requests_successful_count         :integer
#  info_requests_not_held_count           :integer
#  info_requests_overdue_count            :integer
#  info_requests_visible_classified_count :integer
#  info_requests_visible_count            :integer          default(0), not null
#  name                                   :text
#  short_name                             :text
#  request_email                          :text
#  url_name                               :text
#  notes                                  :text
#  first_letter                           :string
#  publication_scheme                     :text
#  disclosure_log                         :text
#

require 'spec_helper'

RSpec.describe PublicBody do

  describe <<-EOF.squish do
    temporary tests for Globalize::ActiveRecord::InstanceMethods#read_attribute
    override
  EOF

    it 'create without translated name' do
      body = FactoryBot.build(:public_body)
      expect(body.update('name' => nil)).to eq(false)
      expect(body).not_to be_valid
    end

    it 'create with translated name' do
      body = FactoryBot.build(:public_body)
      AlaveteliLocalization.with_locale(:es) { body.name = 'hola' }

      expect(body.update('name' => nil)).to eq(false)
      expect(body).not_to be_valid
    end
    it 'update without translated name' do
      body = FactoryBot.create(:public_body)
      body.reload

      expect(body.update('name' => nil)).to eq(false)
      expect(body).not_to be_valid
    end

    it 'update with translated name' do
      body = FactoryBot.create(:public_body)
      AlaveteliLocalization.with_locale(:es) { body.name = 'hola'; body.save! }
      body.reload

      expect(body.update('name' => nil)).to eq(false)
      expect(body).not_to be_valid
    end

    it 'blank string create without translated name' do
      body = FactoryBot.build(:public_body)
      expect(body.update('name' => '')).to eq(false)
      expect(body).not_to be_valid
    end

    it 'blank string create with translated name' do
      body = FactoryBot.build(:public_body)
      AlaveteliLocalization.with_locale(:es) { body.name = 'hola' }

      expect(body.update('name' => '')).to eq(false)
      expect(body).not_to be_valid
    end
    it 'blank string update without translated name' do
      body = FactoryBot.create(:public_body)
      body.reload

      expect(body.update('name' => '')).to eq(false)
      expect(body).not_to be_valid
    end

    it 'blank string update with translated name' do
      body = FactoryBot.create(:public_body)
      AlaveteliLocalization.with_locale(:es) { body.name = 'hola'; body.save! }
      body.reload

      expect(body.update('name' => '')).to eq(false)
      expect(body).not_to be_valid
    end
  end

  describe '.with_domain' do
    subject { described_class.with_domain(domain) }

    let(:public_body_1) do
      FactoryBot.create(:public_body, name: 'B',
                                      request_email: 'B@example.org')
    end

    let(:public_body_2) do
      FactoryBot.create(:public_body, request_email: 'foo@example.com')
    end

    let(:public_body_3) do
      FactoryBot.create(:public_body, name: 'A',
                                      request_email: 'A@example.org')
    end

    context 'when a public body has the domain' do
      let(:domain) { 'example.org' }

      it { is_expected.to match_array([public_body_3, public_body_1]) }
      it { is_expected.not_to include(public_body_2) }
    end

    context 'when the domain is given with a different case' do
      let(:domain) { 'EXAMPLE.ORG' }

      it { is_expected.to match_array([public_body_3, public_body_1]) }
      it { is_expected.not_to include(public_body_2) }
    end

    context 'when domain is nil' do
      let(:domain) { nil }
      it { is_expected.to be_empty }
    end
  end

  describe '.with_tag' do

    it 'should returns all authorities' do
      pbs = PublicBody.with_tag('all')
      expect(pbs).to match_array([
        public_bodies(:geraldine_public_body),
        public_bodies(:humpadink_public_body),
        public_bodies(:forlorn_public_body),
        public_bodies(:silly_walks_public_body),
        public_bodies(:sensible_walks_public_body),
        public_bodies(:other_public_body)
      ])
    end

    it 'should returns authorities without categories' do
      pbs = PublicBody.with_tag('other')
      expect(pbs).to match_array([
        public_bodies(:geraldine_public_body),
        public_bodies(:humpadink_public_body),
        public_bodies(:silly_walks_public_body),
        public_bodies(:sensible_walks_public_body),
        public_bodies(:other_public_body)
      ])
    end

    it 'should return authorities with key/value categories' do
      public_bodies(:humpadink_public_body).tag_string = 'eats_cheese:stilton'

      pbs = PublicBody.with_tag('eats_cheese')
      expect(pbs).to match_array([public_bodies(:humpadink_public_body)])

      pbs = PublicBody.with_tag('eats_cheese:jarlsberg')
      expect(pbs).to be_empty

      pbs = PublicBody.with_tag('eats_cheese:stilton')
      expect(pbs).to match_array([public_bodies(:humpadink_public_body)])
    end

    it 'should return authorities with categories' do
      public_bodies(:humpadink_public_body).tag_string = 'mycategory'

      pbs = PublicBody.with_tag('mycategory')
      expect(pbs).to match_array([public_bodies(:humpadink_public_body)])

      pbs = PublicBody.with_tag('myothercategory')
      expect(pbs).to be_empty
    end

  end

  describe '.without_tag' do

    it 'should not return authorities with key/value categories' do
      public_bodies(:humpadink_public_body).tag_string = 'eats_cheese:stilton'

      pbs = PublicBody.without_tag('eats_cheese')
      expect(pbs).to_not include(public_bodies(:humpadink_public_body))

      pbs = PublicBody.without_tag('eats_cheese:stilton')
      expect(pbs).to_not include(public_bodies(:humpadink_public_body))

      pbs = PublicBody.without_tag('eats_cheese:jarlsberg')
      expect(pbs).to include(public_bodies(:humpadink_public_body))
    end

    it 'should not return authorities with categories' do
      public_bodies(:humpadink_public_body).tag_string = 'mycategory'

      pbs = PublicBody.without_tag('mycategory')
      expect(pbs).to_not include(public_bodies(:humpadink_public_body))

      pbs = PublicBody.without_tag('myothercategory')
      expect(pbs).to include(public_bodies(:humpadink_public_body))
    end

    it 'should be chainable to exclude more than one tag' do
      public_bodies(:geraldine_public_body).tag_string = 'council'
      public_bodies(:humpadink_public_body).tag_string = 'defunct'
      public_bodies(:forlorn_public_body).tag_string = 'not_apply'

      pbs = PublicBody.without_tag('defunct').without_tag('not_apply')
      expect(pbs).to include(public_bodies(:geraldine_public_body))
      expect(pbs).to_not include(public_bodies(:humpadink_public_body))
      expect(pbs).to_not include(public_bodies(:forlorn_public_body))
    end

  end

  describe '.with_query' do

    it 'should return authorities starting with a multibyte first letter' do
      authority = FactoryBot.create(:public_body, name: 'Åčçèñtéd Authority')
      department = FactoryBot.create(:public_body, name: 'Åčçèñtéd Department')

      pbs = PublicBody.with_query('', 'Å')
      expect(pbs).to match_array([authority, department])

      pbs = PublicBody.with_query('Authority', 'Å')
      expect(pbs).to match_array([authority])

      pbs = PublicBody.with_query('Department', 'Å')
      expect(pbs).to match_array([department])
    end

    it 'should ignore tag if greater than one character' do
      pbs = PublicBody.with_query('Department', 'Åč')
      expect(pbs).to match_array([
        public_bodies(:humpadink_public_body),
        public_bodies(:forlorn_public_body)
      ])
    end

  end

  describe '#name' do

    it 'is invalid when nil' do
      subject = described_class.new(:name => nil)
      subject.valid?
      expect(subject.errors[:name]).to eq(["Name can't be blank"])
    end

    it 'is invalid when blank' do
      subject = described_class.new(:name => '')
      subject.valid?
      expect(subject.errors[:name]).to eq(["Name can't be blank"])
    end

    it 'is invalid when not unique' do
      existing = FactoryBot.create(:public_body)
      subject = described_class.new(:name => existing.name)
      subject.valid?
      expect(subject.errors[:name]).to eq(["Name is already taken"])
    end

  end

  describe '#short_name' do

    it 'is invalid when not unique' do
      existing = FactoryBot.create(:public_body, :short_name => 'xyz')
      subject = described_class.new(:short_name => existing.short_name)
      subject.valid?
      expect(subject.errors[:short_name]).to eq(["Short name is already taken"])
    end

    it 'is valid when blank' do
      subject = described_class.new(:short_name => '')
      subject.valid?
      expect(subject.errors[:short_name]).to be_empty
    end

  end

  describe '#request_email' do

    it 'is invalid when nil' do
      subject = described_class.new(:request_email => nil)
      subject.valid?
      expect(subject.errors[:request_email]).
        to eq(["Request email can't be nil"])
    end

    context "when the email is set" do

      subject(:public_body) do
        FactoryBot.build(:public_body,
                         :request_email => "request@example.com")
      end

      it "should return the set email address" do
        expect(public_body.request_email).to eq("request@example.com")
      end

      it "should return a different email address when overridden in configuration" do
        allow(AlaveteliConfiguration).
          to receive(:override_all_public_body_request_emails).
            and_return("tester@example.com")
        expect(public_body.request_email).to eq("tester@example.com")
      end

    end

    context "when no email is set" do

      subject(:public_body) do
        FactoryBot.build(:public_body, :request_email => "")
      end

      it "should return a blank email address" do
        expect(public_body.request_email).to be_blank
      end

      it "should still return a blank email address when overridden in configuration" do
        allow(AlaveteliConfiguration).
          to receive(:override_all_public_body_request_emails).
            and_return("tester@example.com")
        expect(public_body.request_email).to be_blank
      end

    end

    it 'is invalid with an unrequestable email' do
      subject = PublicBody.new(:request_email => 'invalid@')
      subject.valid?
      expect(subject.errors[:request_email]).
        to eq(["Request email doesn't look like a valid email address"])
    end

    it 'is valid with a requestable email' do
      subject = PublicBody.new(:request_email => 'valid@example.com')
      subject.valid?
      expect(subject.errors[:request_email]).to be_empty
    end

  end

  describe '#version' do

    it 'ignores manually set attributes' do
      subject = FactoryBot.build(:public_body, :version => 21)
      subject.save!
      expect(subject.version).to eq(1)
    end

  end

  describe '#url_name' do

    it 'is invalid when nil' do
      subject = PublicBody.new(:url_name => nil)
      subject.valid?
      expect(subject.errors[:url_name]).to eq(["URL name can't be blank"])
    end

    it 'is invalid when blank' do
      subject = PublicBody.new(:url_name => '')
      subject.valid?
      expect(subject.errors[:url_name]).to eq(["URL name can't be blank"])
    end

    it 'is invalid when not unique' do
      existing = FactoryBot.create(:public_body, :url_name => 'xyz')
      subject = described_class.new(:url_name => existing.url_name)
      subject.valid?
      expect(subject.errors[:url_name]).to eq(["URL name is already taken"])
    end

    it 'replaces spaces and makes lower case' do
      subject = PublicBody.new(:name => 'Some Authority')
      expect(subject.url_name).to eq('some_authority')
    end

    it 'does not allow a numeric name' do
      subject = PublicBody.new(:name => '1234')
      expect(subject.url_name).to eq('body')
    end

    context 'short_name has not been set' do

      it 'updates the url_name when name is changed' do
        subject = PublicBody.new
        subject.name = 'Some Authority'
        expect(subject.url_name).to eq('some_authority')
      end

      it 'does not update the url_name if the new body name is invalid' do
        subject = PublicBody.new
        subject.name = '1234'
        expect(subject.url_name).to eq('body')
      end

    end

    context 'short_name has been set' do

      it 'does not update the url_name when name is changed' do
        subject = PublicBody.new(:short_name => 'Test Name')
        subject.name = 'Some Authority'
        expect(subject.url_name).to eq('test_name')
      end

      it 'updates the url_name when short_name is changed' do
        subject = PublicBody.new(:short_name => 'Test Name')
        subject.short_name = 'Short Name'
        expect(subject.url_name).to eq('short_name')
      end

    end

  end

  describe '#first_letter' do

    it 'is empty on initialization' do
      subject = FactoryBot.build(:public_body)
      expect(subject.first_letter).to be_nil
    end

    it 'gets set on save' do
      subject = FactoryBot.build(:public_body, :name => 'Body')
      subject.save!
      expect(subject.first_letter).to eq('B')
    end

    it 'gets updated on save' do
      subject = FactoryBot.create(:public_body, :name => 'Body')
      subject.name = 'Authority'
      expect(subject.first_letter).to eq('B')
      subject.save!
      expect(subject.first_letter).to eq('A')
    end

    it 'sets the first letter to a multibyte character' do
      subject = FactoryBot.build(:public_body, :name => 'åccents')
      subject.save!
      expect(subject.first_letter).to eq('Å')
    end

    it 'should save the first letter of a translation' do
      subject = FactoryBot.build(:public_body, :name => 'Body')
      AlaveteliLocalization.with_locale(:es) do
        subject.name = 'Prueba body'
        subject.save!
        expect(subject.first_letter).to eq('P')
      end
    end

    it 'saves the first letter of a translation, even when it is the same as the
          first letter in the default locale' do
      subject = FactoryBot.build(:public_body, :name => 'Body')
      AlaveteliLocalization.with_locale(:es) do
        subject.name = 'Body ES'
        subject.save!
        expect(subject.first_letter).to eq('B')
      end
    end

  end

  describe '#api_key' do

    it 'is empty on initialization' do
      subject = FactoryBot.build(:public_body)
      expect(subject.api_key).to be_nil
    end

    it 'gets set on save' do
      subject = FactoryBot.build(:public_body)
      subject.save!
      expect(subject.api_key).not_to be_blank
    end

    it 'does not get changed on update' do
      subject = FactoryBot.create(:public_body)
      existing = subject.api_key
      subject.save!
      expect(subject.api_key).to eq(existing)
    end

  end

  describe '#last_edit_editor' do

    it 'is invalid when nil' do
      subject = PublicBody.new(:last_edit_editor => nil)
      subject.valid?
      expect(subject.errors[:last_edit_editor]).
        to eq(["Last edit editor can't be blank"])
    end

    it 'is invalid when blank' do
      subject = PublicBody.new(:last_edit_editor => '')
      subject.valid?
      expect(subject.errors[:last_edit_editor]).
        to eq(["Last edit editor can't be blank"])
    end

    it 'is invalid when over 255 characters' do
      subject = PublicBody.new(:last_edit_editor => 'x' * 256)
      subject.valid?
      expect(subject.errors[:last_edit_editor]).
        to eq(["Last edit editor can't be longer than 255 characters"])
    end

    it 'is valid up to 255 characters' do
      subject = PublicBody.new(:last_edit_editor => 'x' * 255)
      subject.valid?
      expect(subject.errors[:last_edit_editor]).to be_empty
    end

  end

  describe '#last_edit_comment' do

    it 'is valid when nil' do
      subject = PublicBody.new(:last_edit_comment => nil)
      subject.valid?
      expect(subject.errors[:last_edit_comment]).to be_empty
    end

    it 'strips blank attributes' do
      subject = FactoryBot.create(:public_body, :last_edit_comment => '')
      expect(subject.last_edit_comment).to be_nil
    end

  end

  describe '#home_page' do

    it 'is valid when nil' do
      subject = PublicBody.new(:home_page => nil)
      subject.valid?
      expect(subject.errors[:home_page]).to be_empty
    end

    it 'strips blank attributes' do
      subject = FactoryBot.create(:public_body, :home_page => '')
      expect(subject.home_page).to be_nil
    end

  end

  describe '#notes' do

    it 'is valid when nil' do
      subject = PublicBody.new(:notes => nil)
      subject.valid?
      expect(subject.errors[:notes]).to be_empty
    end

    it 'strips blank attributes' do
      subject = FactoryBot.create(:public_body, :notes => '')
      expect(subject.notes).to be_nil
    end

  end

  describe '#has_notes?' do

    it 'returns false if notes is nil' do
      subject = PublicBody.new(:notes => nil)
      expect(subject.has_notes?).to eq(false)
    end

    it 'returns false if notes is blank' do
      subject = PublicBody.new(:notes => '')
      expect(subject.has_notes?).to eq(false)
    end

    it 'returns true if notes are present' do
      subject = PublicBody.new(:notes => 'x')
      expect(subject.has_notes?).to eq(true)
    end

    context 'when the authority is tagged with the tag option' do

      it 'returns true if the authority has notes' do
        subject = PublicBody.new(:notes => 'x', :tag_string => 'popular')
        expect(subject.has_notes?(tag: 'popular')).to eq(true)
      end

      it 'returns false if the authority does not have notes' do
        subject = PublicBody.new(:notes => nil, :tag_string => 'popular')
        expect(subject.has_notes?(tag: 'popular')).to eq(false)
      end

    end

    context 'when the authority is not tagged with the tag option' do

      it 'returns false' do
        subject = PublicBody.new(:notes => 'x', :tag_string => 'useless')
        expect(subject.has_notes?(tag: 'popular')).to eq(false)
      end

    end

  end

  describe '#publication_scheme' do

    it 'is valid when nil' do
      subject = PublicBody.new(:publication_scheme => nil)
      subject.valid?
      expect(subject.errors[:publication_scheme]).to be_empty
    end

    it 'strips blank attributes' do
      subject = FactoryBot.create(:public_body, :publication_scheme => '')
      expect(subject.publication_scheme).to be_nil
    end

  end

  describe '#disclosure_log' do

    it 'is valid when nil' do
      subject = PublicBody.new(:disclosure_log => nil)
      subject.valid?
      expect(subject.errors[:disclosure_log]).to be_empty
    end

    it 'strips blank attributes' do
      subject = FactoryBot.create(:public_body, :disclosure_log => '')
      expect(subject.disclosure_log).to be_nil
    end

  end

  describe '#translations_attributes=' do

    context 'translation_attrs is a Hash' do

      it 'does not persist translations' do
        body = FactoryBot.create(:public_body)
        body.translations_attributes = { :es => { :locale => 'es',
                                                  :name => 'El Body' } }

        expect(PublicBody.find(body.id).translations.size).to eq(1)
      end

      it 'creates a new translation' do
        body = FactoryBot.create(:public_body)
        body.translations_attributes = { :es => { :locale => 'es',
                                                  :name => 'El Body' } }
        body.save!
        body.reload
        expect(body.name(:es)).to eq('El Body')
      end

      it 'updates an existing translation' do
        body = FactoryBot.create(:public_body)
        body.translations_attributes = { 'es' => { :locale => 'es',
                                                   :name => 'El Body' } }
        body.save!

        body.translations_attributes = { 'es' => { :id => body.translation_for(:es).id,
                                                   :locale => 'es',
                                                   :name => 'Renamed' } }
        body.save!
        expect(body.name(:es)).to eq('Renamed')
      end

      it 'updates an existing translation and creates a new translation' do
        body = FactoryBot.create(:public_body)
        body.translations.create(:locale => 'es',
                                 :name => 'El Body')

        expect(body.translations.size).to eq(2)

        body.translations_attributes = {
          'es' => { :id => body.translation_for(:es).id,
                    :locale => 'es',
                    :name => 'Renamed' },
          'fr' => { :locale => 'fr',
                    :name => 'Le Body' }
        }

        expect(body.translations.size).to eq(3)
        AlaveteliLocalization.with_locale(:es) do
          expect(body.name).to eq('Renamed')
        end
        AlaveteliLocalization.with_locale(:fr) do
          expect(body.name).to eq('Le Body')
        end
      end

      it 'skips empty translations' do
        body = FactoryBot.create(:public_body)
        body.translations.create(:locale => 'es',
                                 :name => 'El Body')

        expect(body.translations.size).to eq(2)

        body.translations_attributes = {
          'es' => { :id => body.translation_for(:es).id,
                    :locale => 'es',
                    :name => 'Renamed' },
          'fr' => { :locale => 'fr' }
        }

        expect(body.translations.size).to eq(2)
      end
    end
  end

  describe '#set_api_key' do

    it 'generates and sets an API key' do
      allow(SecureRandom).to receive(:base64).and_return('APIKEY')
      body = PublicBody.new
      body.set_api_key
      expect(body.api_key).to eq('APIKEY')
    end

    it 'does not overwrite an existing API key' do
      allow(SecureRandom).to receive(:base64).and_return('APIKEY')
      body = PublicBody.new(:api_key => 'EXISTING')
      body.set_api_key
      expect(body.api_key).to eq('EXISTING')
    end

  end

  describe '#set_api_key!' do

    it 'generates and sets an API key' do
      allow(SecureRandom).to receive(:base64).and_return('APIKEY')
      body = PublicBody.new
      body.set_api_key!
      expect(body.api_key).to eq('APIKEY')
    end

    it 'overwrites an existing API key' do
      allow(SecureRandom).to receive(:base64).and_return('APIKEY')
      body = PublicBody.new(:api_key => 'EXISTING')
      body.set_api_key!
      expect(body.api_key).to eq('APIKEY')
    end

  end

  describe '#expire_requests' do
    it 'calls expire on all associated requests' do
      public_body = FactoryBot.build(:public_body)

      request_1, request_2 = double(:info_request), double(:info_request)

      allow(public_body).to receive_message_chain(:info_requests, :find_each).
        and_yield(request_1).and_yield(request_2)

      expect(request_1).to receive(:expire)
      expect(request_2).to receive(:expire)

      public_body.expire_requests
    end
  end

  describe '#short_or_long_name' do

    it 'returns the short_name if it has been set' do
      public_body = PublicBody.new(:name => 'Test Name', :short_name => "Test")
      expect(public_body.short_or_long_name).to eq('Test')
    end

    it 'returns the name if short_name has not been set' do
      public_body = PublicBody.new(:name => 'Test Name')
      expect(public_body.short_or_long_name).to eq('Test Name')
    end

  end

  describe '#set_first_letter' do

    it 'sets first_letter to the first letter of the name if the name is set' do
      public_body = PublicBody.new(:name => 'Test Name')
      public_body.set_first_letter
      expect(public_body.first_letter).to eq('T')
    end

    it 'does not set first_letter if the name has not been set' do
      public_body = PublicBody.new
      public_body.set_first_letter
      expect(public_body.first_letter).to be_nil
    end

    it 'handles mutlibyte characters correctly' do
      public_body = PublicBody.new(:name => 'Åccented')
      public_body.set_first_letter
      expect(public_body.first_letter).to eq('Å')
    end

    it 'upcases the first character' do
      public_body = PublicBody.new(:name => 'åccented')
      public_body.set_first_letter
      expect(public_body.first_letter).to eq('Å')
    end

  end

  describe '#not_subject_to_law?' do

    it 'returns true if tagged with "foi_no"' do
      public_body = FactoryBot.build(:public_body,
                                     tag_string: 'foi_no')
      expect(public_body.not_subject_to_law?).to eq true
    end

    it 'returns false if not tagged with "foi_no"' do
      public_body = FactoryBot.build(:public_body)
      expect(public_body.not_subject_to_law?).to eq false
    end

    it 'returns true if authority_must_respond has been set to false in config' do
      allow(AlaveteliConfiguration).to receive(:authority_must_respond).
        and_return(false)
      public_body = FactoryBot.build(:public_body)
      expect(public_body.not_subject_to_law?).to eq true
    end

  end

  describe ".internal_admin_body" do

    before(:each) do
      InfoRequest.destroy_all
      PublicBody.destroy_all
    end

    it "creates the internal_admin_body if it didn't exist" do
      iab = PublicBody.internal_admin_body
      expect(iab).to be_persisted
    end

    it 'creates the internal_admin_body with the default_locale' do
      iab = PublicBody.internal_admin_body
      expect(iab.translations.first.locale).to eq(:en)
    end

    it 'handles underscore locales correctly' do
      AlaveteliLocalization.set_locales('es en_GB', 'en_GB')
      iab = PublicBody.internal_admin_body
      expect(iab.translations.first.locale).to eq(:en_GB)
    end

    it "repairs the internal_admin_body if the default locale has changed" do
      iab = PublicBody.internal_admin_body

      with_default_locale(:es) do
        AlaveteliLocalization.with_locale(:es) do
          found_iab = PublicBody.internal_admin_body
          expect(found_iab).to eq(iab)
          expect(found_iab.translations.pluck(:locale)).to include('es')
        end
      end
    end

    it "finds the internal_admin_body if current locale is not the default" do
      iab = PublicBody.internal_admin_body

      AlaveteliLocalization.with_locale(:es) do
        found_iab = PublicBody.internal_admin_body
        expect(found_iab).to eq(iab)
      end
    end

  end

  describe '.localized_csv_field_name' do

    it 'returns the field name if passed the default_locale' do
      expect(PublicBody.localized_csv_field_name(:en, "first_letter")).
        to eq("first_letter")
    end

    context 'the default_locale contains an underscore' do

      it 'returns the field name if passed the default_locale' do
        AlaveteliLocalization.set_locales('en_GB es', 'en_GB')
        expect(PublicBody.localized_csv_field_name(:en_GB, "first_letter")).
          to eq("first_letter")
      end

    end

    it 'returns appends the locale name if passed a non default locale' do
      expect(PublicBody.localized_csv_field_name(:es, "first_letter")).
        to eq("first_letter.es")
    end

  end

  describe '.without_request_email' do
    subject { PublicBody.without_request_email }

    let!(:public_body) { FactoryBot.create(:public_body) }
    let!(:blank_body) { FactoryBot.create(:blank_email_public_body) }
    let!(:defunct_body) do
      FactoryBot.create(:public_body, :defunct, request_email: '')
    end

    it 'does not include bodies with a request email' do
      is_expected.to_not include(public_body)
    end

    it 'includes bodies with an empty request email' do
      is_expected.to include(blank_body)
    end

    it 'does not include defunct bodies' do
      is_expected.to_not include(defunct_body)
    end

    it 'includes bodies with a translation that has an empty request email' do
      AlaveteliLocalization.with_locale(:es) do
        public_body.request_email = ''
        public_body.save!
      end
      is_expected.to include(blank_body)
    end

  end

  describe '.with_request_email' do
    subject { PublicBody.with_request_email }

    let!(:public_body) { FactoryBot.create(:public_body) }
    let!(:blank_body) { FactoryBot.create(:blank_email_public_body) }

    it 'include bodies with a request email' do
      is_expected.to include(public_body)
    end

    it 'does not include bodies with an empty request email' do
      is_expected.to_not include(blank_body)
    end

  end

  describe 'when generating json for the api' do

    let(:public_body) do
      FactoryBot.create(:public_body,
                        :name => 'Marmot Appreciation Society',
                        :short_name => 'MAS',
                        :request_email => 'marmots@flourish.org',
                        :last_edit_editor => 'test',
                        :last_edit_comment => '',
                        :info_requests_count => 10,
                        :info_requests_successful_count => 2,
                        :info_requests_not_held_count   => 2,
                        :info_requests_overdue_count    => 3,
                        :info_requests_visible_classified_count => 3)
    end

    it 'should return info about request counts' do
      expect(public_body.json_for_api).
        to eq(
            {
              :name => 'Marmot Appreciation Society',
              :notes => "",
              :publication_scheme => "",
              :short_name => "MAS",
              :tags => [],
              :updated_at => public_body.updated_at,
              :url_name => "mas",
              :created_at => public_body.created_at,
              :home_page => "http://www.flourish.org",
              :id => public_body.id,
              :info => {
                :requests_count => 10,
                :requests_successful_count => 2,
                :requests_not_held_count   => 2,
                :requests_overdue_count    => 3,
                :requests_visible_classified_count => 3,
              }
            })
    end

  end

end

RSpec.describe PublicBody, " using tags" do
  before do
    @public_body = PublicBody.new(:name => 'Aardvark Monitoring Service',
                                  :short_name => 'AMS',
                                  :request_email => 'foo@flourish.org',
                                  :last_edit_editor => 'test',
                                  :last_edit_comment => '')
  end

  it 'should correctly convert a tag string into tags' do
    @public_body.tag_string = 'stilton emmental'
    expect(@public_body.tag_string).to eq('stilton emmental')

    expect(@public_body.has_tag?('stilton')).to be true
    expect(@public_body.has_tag?('emmental')).to be true
    expect(@public_body.has_tag?('jarlsberg')).to be false
  end

  it 'should strip spaces from tag strings' do
    @public_body.tag_string = ' chesire  lancashire'
    expect(@public_body.tag_string).to eq('chesire lancashire')
  end

  it 'should work with other white space, such as tabs and new lines' do
    @public_body.tag_string = "chesire\n\tlancashire"
    expect(@public_body.tag_string).to eq('chesire lancashire')
  end

  it 'changing tags should remove presence of the old ones' do
    @public_body.tag_string = 'stilton'
    expect(@public_body.tag_string).to eq('stilton')

    expect(@public_body.has_tag?('stilton')).to be true
    expect(@public_body.has_tag?('jarlsberg')).to be false

    @public_body.tag_string = 'jarlsberg'
    expect(@public_body.tag_string).to eq('jarlsberg')

    expect(@public_body.has_tag?('stilton')).to be false
    expect(@public_body.has_tag?('jarlsberg')).to be true
  end

  it 'should be able to append tags' do
    expect(@public_body.tag_string).to eq('')
    @public_body.add_tag_if_not_already_present('cheddar')

    expect(@public_body.tag_string).to eq('cheddar')
    expect(@public_body.has_tag?('cheddar')).to be true
  end

  it 'should ignore repeat tags' do
    @public_body.tag_string = 'stilton stilton'
    expect(@public_body.tag_string).to eq('stilton')
  end
end

RSpec.describe PublicBody, " using machine tags" do
  before do
    @public_body = PublicBody.new(:name => 'Aardvark Monitoring Service',
                                  :short_name => 'AMS',
                                  :request_email => 'foo@flourish.org',
                                  :last_edit_editor => 'test',
                                  :last_edit_comment => '')
  end

  it 'should parse machine tags' do
    @public_body.tag_string = 'wondrous cheese:green'
    expect(@public_body.tag_string).to eq('wondrous cheese:green')

    expect(@public_body.has_tag?('cheese:green')).to be false
    expect(@public_body.has_tag?('cheese')).to be true
    expect(@public_body.get_tag_values('cheese')).to eq(['green'])

    expect(@public_body.get_tag_values('wondrous')).to eq([])
    lambda {
      expect(@public_body.get_tag_values('notthere')).to raise_error(PublicBody::TagNotFound)
    }
  end

  it 'should cope with colons in value' do
    @public_body.tag_string = 'url:http://www.flourish.org'
    expect(@public_body.tag_string).to eq('url:http://www.flourish.org')

    expect(@public_body.has_tag?('url')).to be true
    expect(@public_body.get_tag_values('url')).to eq(['http://www.flourish.org'])
  end

  it 'should allow multiple tags of the same sort' do
    @public_body.tag_string = 'url:http://www.theyworkforyou.com/ url:http://www.fixmystreet.com/'
    expect(@public_body.has_tag?('url')).to be true
    expect(@public_body.get_tag_values('url')).to eq(['http://www.theyworkforyou.com/', 'http://www.fixmystreet.com/'])
  end
end

RSpec.describe PublicBody, "when finding_by_tags" do

  before do
    @geraldine = public_bodies(:geraldine_public_body)
    @geraldine.tag_string = 'rabbit'
    @humpadink = public_bodies(:humpadink_public_body)
    @humpadink.tag_string = 'coney:5678 coney:1234'
  end

  it 'should be able to find bodies by string' do
    found = PublicBody.find_by_tag('rabbit')
    expect(found).to eq([ @geraldine ])
  end

  it 'should be able to find when there are multiple tags in one body, without returning duplicates' do
    found = PublicBody.find_by_tag('coney')
    expect(found).to eq([ @humpadink ])
  end
end

RSpec.describe PublicBody, " when saving" do
  before do
    @public_body = PublicBody.new
  end

  def set_default_attributes(public_body)
    public_body.name = "Testing Public Body"
    public_body.short_name = "TPB"
    public_body.request_email = "request@localhost"
    public_body.last_edit_editor = "*test*"
    public_body.last_edit_comment = "This is a test"
  end

  it "should not be valid without setting some parameters" do
    expect(@public_body).not_to be_valid
  end

  it "should not be valid with misformatted request email" do
    set_default_attributes(@public_body)
    @public_body.request_email = "requestBOOlocalhost"
    expect(@public_body).not_to be_valid
    expect(@public_body.errors[:request_email].size).to eq(1)
  end

  it "should save" do
    set_default_attributes(@public_body)
    @public_body.save!
  end

  it 'should create a url_name for a translation' do
    existing = FactoryBot.create(:public_body, :first_letter => 'T', :short_name => 'Test body')
    AlaveteliLocalization.with_locale(:es) do
      existing.update :short_name => 'Prueba', :name => 'Prueba body'
      expect(existing.url_name).to eq('prueba')
    end
  end

  it "should save the name when renaming an existing public body" do
    public_body = public_bodies(:geraldine_public_body)
    public_body.name = "Mark's Public Body"
    public_body.save!

    expect(public_body.name).to eq("Mark's Public Body")
  end

  it 'should update the right translation when in a locale with an underscore' do
    AlaveteliLocalization.set_locales('he_IL', 'he_IL')
    public_body = public_bodies(:humpadink_public_body)
    translation_count = public_body.translations.size
    public_body.name = 'Renamed'
    public_body.save!
    expect(public_body.translations.size).to eq(translation_count)
  end

  it 'should not create a new version when nothing has changed' do
    expect(@public_body.versions.size).to eq(0)
    set_default_attributes(@public_body)
    @public_body.save!
    expect(@public_body.versions.size).to eq(1)
    @public_body.save!
    expect(@public_body.versions.size).to eq(1)
  end

  it 'should create a new version if something has changed' do
    expect(@public_body.versions.size).to eq(0)
    set_default_attributes(@public_body)
    @public_body.save!
    expect(@public_body.versions.size).to eq(1)
    @public_body.name = 'Test'
    @public_body.save!
    expect(@public_body.versions.size).to eq(2)
    expect(@public_body.versions.last.name).to eq('Test')
  end

  it 'reindexes request events when url_name has changed' do
    body = FactoryBot.create(:public_body, name: 'foo-bar-baz')
    requests =
      2.times.map { FactoryBot.create(:info_request, public_body: body) }
    event_ids = InfoRequestEvent.where(info_request_id: requests.map(&:id))

    ActsAsXapian::ActsAsXapianJob.destroy_all

    body.update!(url_name: 'baz-bar-foo')

    expected_events =
      ActsAsXapian::ActsAsXapianJob.
      where(action: 'update', model: 'InfoRequestEvent', model_id: event_ids)

    expect(expected_events.size).to eq(event_ids.size)
  end

  it 'does not reindex request events when url_name has not changed' do
    body = FactoryBot.create(:public_body, name: 'foo-bar-baz')
    FactoryBot.create(:info_request, public_body: body)

    ActsAsXapian::ActsAsXapianJob.destroy_all

    body.update!(notes: 'test')

    expected_events =
      ActsAsXapian::ActsAsXapianJob.
      where(action: 'update', model: 'InfoRequestEvent')

    expect(expected_events.count).to eq(0)
  end
end

RSpec.describe PublicBody, "when searching" do

  it "should find by existing url name" do
    body = PublicBody.find_by_url_name_with_historic('dfh')
    expect(body.id).to eq(3)
  end

  it "should find by historic url name" do
    body = PublicBody.find_by_url_name_with_historic('hdink')
    expect(body.id).to eq(3)
    expect(body.class.to_s).to eq('PublicBody')
  end

  it "should cope with not finding any" do
    body = PublicBody.find_by_url_name_with_historic('idontexist')
    expect(body).to be_nil
  end

  it "should cope with duplicate historic names" do
    body = PublicBody.find_by_url_name_with_historic('dfh')

    # create history with short name "mouse" twice in it
    body.short_name = 'Mouse'
    expect(body.url_name).to eq('mouse')
    body.save!
    body.request_email = 'dummy@localhost'
    body.save!
    # but a different name now
    body.short_name = 'Stilton'
    expect(body.url_name).to eq('stilton')
    body.save!

    # try and find by it
    body = PublicBody.find_by_url_name_with_historic('mouse')
    expect(body.id).to eq(3)
    expect(body.class.to_s).to eq('PublicBody')
  end

  it "should cope with same url_name across multiple locales" do
    AlaveteliLocalization.with_locale(:es) do
      # use the unique spanish name to retrieve and edit
      body = PublicBody.find_by_url_name_with_historic('etgq')
      body.short_name = 'tgq' # Same as english version
      body.save!

      # now try to retrieve it
      body = PublicBody.find_by_url_name_with_historic('tgq')
      expect(body.id).to eq(public_bodies(:geraldine_public_body).id)
      expect(body.name).to eq("El A Geraldine Quango")
    end
  end

  it 'should not raise an error on a name with a single quote in it' do
    body = PublicBody.find_by_url_name_with_historic("belfast city council'")
  end
end

RSpec.describe PublicBody, "when destroying" do
  let(:public_body) { FactoryBot.create(:public_body) }

  it 'should destroy the public_body' do
    public_body.destroy
    expect(PublicBody.where(:id => public_body.id)).to be_empty
  end

  it 'should destroy the associated track_things' do
    FactoryBot.create(:public_body_track,
                      :public_body => public_body,
                      :track_medium => 'email_daily',
                      :track_query => 'test')
    public_body.destroy
    expect(TrackThing.where(:public_body_id => public_body.id)).to be_empty
  end

  it 'should destroy the associated censor_rules' do
    FactoryBot.create(:censor_rule, :public_body => public_body)
    public_body.destroy
    expect(CensorRule.where(:public_body_id => public_body.id)).to be_empty
  end

  it 'destroys associated translations' do
    AlaveteliLocalization.with_locale(:es) do
      public_body.name = 'El Translation'
      public_body.save!
    end
    expect(PublicBody::Translation.where(:public_body_id => public_body.id)).
      to_not be_empty
    public_body.destroy
    expect(PublicBody::Translation.where(:public_body_id => public_body.id)).
      to be_empty
  end

  it 'should raise an error if there are associated info_requests' do
    FactoryBot.create(:info_request, :public_body => public_body)
    public_body.reload
    expect { public_body.destroy }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

end

RSpec.describe PublicBody, " when loading CSV files" do
  before(:each) do
    # InternalBody is created the first time it's accessed, which happens sometimes during imports,
    # depending on the tag used. By accessing it here before every test, it doesn't disturb our checks later on
    PublicBody.internal_admin_body
  end

  it "should import even if no email is provided" do
    errors, notes = PublicBody.import_csv("1,aBody", '', 'replace', true, 'someadmin') # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(2)
    expect(notes[0]).to eq("line 1: creating new authority 'aBody' (locale: en):\n\t{\"name\":\"aBody\"}")
    expect(notes[1]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)
  end

  it "should do a dry run successfully" do
    original_count = PublicBody.count

    csv_contents = normalize_string_to_utf8(load_file_fixture("fake-authority-type.csv"))
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin') # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(6)
    expect(notes[0..4]).to eq([
      "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}",
      "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}",
      "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
      "line 4: creating new authority 'Gobierno de Aragón' (locale: en):\n\t\{\"name\":\"Gobierno de Aragón\",\"request_email\":\"spain_foi@localhost\"}",
      "line 5: creating new authority 'Nordic æøå' (locale: en):\n\t{\"name\":\"Nordic æøå\",\"request_email\":\"no_foi@localhost\"}"
    ])
    expect(notes[5]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count)
  end

  it "should do full run successfully" do
    original_count = PublicBody.count

    csv_contents = normalize_string_to_utf8(load_file_fixture("fake-authority-type.csv"))
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run
    expect(errors).to eq([])
    expect(notes.size).to eq(6)
    expect(notes[0..4]).to eq([
      "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}",
      "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}",
      "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
      "line 4: creating new authority 'Gobierno de Aragón' (locale: en):\n\t\{\"name\":\"Gobierno de Aragón\",\"request_email\":\"spain_foi@localhost\"}",
      "line 5: creating new authority 'Nordic æøå' (locale: en):\n\t{\"name\":\"Nordic æøå\",\"request_email\":\"no_foi@localhost\"}"
    ])
    expect(notes[5]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count + 5)
  end

  it "should do imports without a tag successfully" do
    original_count = PublicBody.count

    csv_contents = normalize_string_to_utf8(load_file_fixture("fake-authority-type.csv"))
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run
    expect(errors).to eq([])
    expect(notes.size).to eq(6)
    expect(notes[0..4]).to eq([
      "line 1: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\"\}",
      "line 2: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\"\}",
      "line 3: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\"\}",
      "line 4: creating new authority 'Gobierno de Aragón' (locale: en):\n\t\{\"name\":\"Gobierno de Aragón\",\"request_email\":\"spain_foi@localhost\"}",
      "line 5: creating new authority 'Nordic æøå' (locale: en):\n\t{\"name\":\"Nordic æøå\",\"request_email\":\"no_foi@localhost\"}"
    ])
    expect(notes[5]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)
    expect(PublicBody.count).to eq(original_count + 5)
  end

  it "should handle a field list and fields out of order" do
    original_count = PublicBody.count

    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin') # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(4)
    expect(notes[0..2]).to eq([
      "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t\{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"\}",
      "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t\{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"\}",
      "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t\{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"\}",
    ])
    expect(notes[3]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count)
  end

  it "should import tags successfully when the import tag is not set" do
    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin') # false means real run

    expect(PublicBody.find_by_name('North West Fake Authority').tag_array_for_search).to eq([])
    expect(PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search).to eq(['scottish'])
    expect(PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search).to eq(['aTag', 'fake'])

    # Import again to check the 'add' tag functionality works
    new_tags_file = load_file_fixture('fake-authority-add-tags.csv')
    errors, notes = PublicBody.import_csv(new_tags_file, '', 'add', false, 'someadmin') # false means real run

    # Check tags were added successfully
    expect(PublicBody.find_by_name('North West Fake Authority').tag_array_for_search).to eq(['aTag'])
    expect(PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search).to eq(['aTag', 'scottish'])
    expect(PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search).to eq(['aTag', 'fake'])
  end

  it "should import tags successfully when the import tag is set" do
    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    errors, notes = PublicBody.import_csv(csv_contents, 'fake', 'add', false, 'someadmin') # false means real run

    # Check new bodies were imported successfully
    expect(PublicBody.find_by_name('North West Fake Authority').tag_array_for_search).to eq(['fake'])
    expect(PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search).to eq(['fake', 'scottish'])
    expect(PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search).to eq(['aTag', 'fake'])

    # Import again to check the 'replace' tag functionality works
    new_tags_file = load_file_fixture('fake-authority-add-tags.csv')
    errors, notes = PublicBody.import_csv(new_tags_file, 'fake', 'replace', false, 'someadmin') # false means real run

    # Check tags were added successfully
    expect(PublicBody.find_by_name('North West Fake Authority').tag_array_for_search).to eq(['aTag', 'fake'])
    expect(PublicBody.find_by_name('Scottish Fake Authority').tag_array_for_search).to eq(['aTag', 'fake'])
    expect(PublicBody.find_by_name('Fake Authority of Northern Ireland').tag_array_for_search).to eq(['aTag', 'fake'])
  end


  context 'when the import tag is set' do

    context 'with a new body' do

      it 'appends the import tag when no tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'add', false, 'someadmin')

        expected = %W(imported)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'appends the import tag when a tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,first_tag second_tag,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'add', false, 'someadmin')

        expected = %W(first_tag imported second_tag)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'replaces with the import tag when no tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'replace', false, 'someadmin')

        expected = %W(imported)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'replaces with the import tag and tag_string when a tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,first_tag second_tag,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'replace', false, 'someadmin')

        expected = %W(first_tag imported second_tag)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

    end

    context 'an existing body without tags' do

      before do
        @body = FactoryBot.create(:public_body, :name => 'Existing Body')
      end

      it 'will not import if there is an existing body without the tag' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        errors, notes = PublicBody.import_csv(csv, 'imported', 'add', false, 'someadmin')

        expected = %W(imported)
        expect(errors).to include("error: line 2: Name Name is already taken for authority 'Existing Body'")
      end

    end

    context 'an existing body with tags' do

      before do
        @body = FactoryBot.create(:public_body, :tag_string => 'imported first_tag second_tag')
      end

      it 'created with tags, different tags in csv, add import tag' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }","first_tag new_tag",#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'add', false, 'someadmin')
        expected = %W(first_tag imported new_tag second_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'created with tags, different tags in csv, replace import tag' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }","first_tag new_tag",#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, 'imported', 'replace', false, 'someadmin')

        expected = %W(first_tag imported new_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

    end

  end

  context 'when the import tag is not set' do

    context 'with a new body' do

      it 'it is empty if no tag_string is set' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = []
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'uses the specified tag_string' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,first_tag,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = %W(first_tag)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'replaces with empty if no tag_string is set' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = []
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

      it 'replaces with the specified tag_string' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        ,q@localhost,Quango,first_tag,http://example.org
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = %W(first_tag)
        expect(PublicBody.find_by_name('Quango').tag_array_for_search).to eq(expected)
      end

    end

    context 'with an existing body without tags' do

      before do
        @body = FactoryBot.create(:public_body)
      end

      it 'appends when no tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = []
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'appends when a tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",new_tag,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = %W(new_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'replaces when no tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = []
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'replaces when a tag_string is specified' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }",new_tag,#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = %W(new_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

    end

    describe 'with an existing body with tags' do

      before do
        @body = FactoryBot.create(:public_body, :tag_string => 'first_tag second_tag')
      end

      it 'created with tags, different tags in csv, add tags' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }","first_tag new_tag",#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'add', false, 'someadmin')

        expected = %W(first_tag new_tag second_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

      it 'created with tags, different tags in csv, replace' do
        csv = <<-CSV.strip_heredoc
        #id,request_email,name,tag_string,home_page
        #{ @body.id },#{ @body.request_email },"#{ @body.name }","first_tag new_tag",#{ @body.home_page }
        CSV

        # csv, tag, tag_behaviour, dry_run, editor
        PublicBody.import_csv(csv, '', 'replace', false, 'someadmin')

        expected = %W(first_tag new_tag)
        expect(PublicBody.find(@body.id).tag_array_for_search).to eq(expected)
      end

    end

  end

  it "should create bodies with names in multiple locales" do
    original_count = PublicBody.count

    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', false, 'someadmin', [:en, :es])
    expect(errors).to eq([])
    expect(notes.size).to eq(7)
    expect(notes[0..5]).to eq([
      "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"}",
      "line 2: creating new authority 'North West Fake Authority' (locale: es):\n\t{\"name\":\"Autoridad del Nordeste\"}",
      "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"}",
      "line 3: creating new authority 'Scottish Fake Authority' (locale: es):\n\t{\"name\":\"Autoridad Escocesa\"}",
      "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"}",
      "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: es):\n\t{\"name\":\"Autoridad Irlandesa\"}",
    ])
    expect(notes[6]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count + 3)

    # TODO: Not sure why trying to do a I18n.with_locale fails here. Seems related to
    # the way categories are loaded every time from the PublicBody class. For now we just
    # test some translation was done.
    body = PublicBody.find_by_name('North West Fake Authority')
    expect(body.translated_locales.map { |l|l.to_s }.sort).to eq(["en", "es"])
  end

  it "should not fail if a locale is not found in the input file" do
    original_count = PublicBody.count

    csv_contents = load_file_fixture("fake-authority-type-with-field-names.csv")
    # Depending on the runtime environment (Ruby version? OS?) the list of available locales
    # is made of strings or symbols, so we use 'en' here as a string to test both scenarios.
    # See https://github.com/mysociety/alaveteli/issues/193
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin', ['en', :xx]) # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(4)
    expect(notes[0..2]).to eq([
      "line 2: creating new authority 'North West Fake Authority' (locale: en):\n\t{\"name\":\"North West Fake Authority\",\"request_email\":\"north_west_foi@localhost\",\"home_page\":\"http://northwest.org\"}",
      "line 3: creating new authority 'Scottish Fake Authority' (locale: en):\n\t{\"name\":\"Scottish Fake Authority\",\"request_email\":\"scottish_foi@localhost\",\"home_page\":\"http://scottish.org\",\"tag_string\":\"scottish\"}",
      "line 4: creating new authority 'Fake Authority of Northern Ireland' (locale: en):\n\t{\"name\":\"Fake Authority of Northern Ireland\",\"request_email\":\"ni_foi@localhost\",\"tag_string\":\"fake aTag\"}",
    ])
    expect(notes[3]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count)
  end

  context 'when importing data from a CSV' do

    before do
      InfoRequest.destroy_all
      PublicBody.destroy_all
      PublicBody.internal_admin_body
    end

    let(:filename) do
      file_fixture_name('fake-authority-type-with-field-names.csv')
    end

    it "is able to load CSV from a file as well as a string" do
      # Essentially the same code is used for import_csv_from_file
      # as import_csv, so this is just a basic check that
      # import_csv_from_file can load from a file at all. (It would
      # be easy to introduce a regression that broke this, because
      # of the confusing change in behaviour of CSV.parse between
      # Ruby 1.8 and 1.9.)
      original_count = PublicBody.count
      PublicBody.
        import_csv_from_file(filename, '', 'replace', false, 'someadmin')
      expect(PublicBody.count).to eq(original_count + 3)
    end

    it 'recognises an underscore locale as the default' do
      AlaveteliLocalization.set_locales('es en_GB', 'en_GB')
      PublicBody.
        import_csv_from_file(filename, '', 'replace', false, 'someadmin')

      expect(
        PublicBody.joins(:translations).
          where("public_body_translations.name != 'Internal admin authority'").
            first.
              translations.
                first.
                  locale
      ).to eq(:en_GB)
    end

  end

  it "should handle active record validation errors" do
    csv = <<-CSV
#name,request_email,short_name
Foobar,a@example.com,foobar
Foobar Test,b@example.com,foobar
CSV

    csv_contents = normalize_string_to_utf8(csv)
    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin') # true means dry run

    expect(errors).to include("error: line 3: Url name URL name is already taken for authority 'Foobar Test'")
  end

  it 'has a default list of fields to import' do
    expected_fields = [
      ['name', '(i18n)<strong>Existing records cannot be renamed</strong>'],
      ['short_name', '(i18n)'],
      ['request_email', '(i18n)'],
      ['notes', '(i18n)'],
      ['publication_scheme', '(i18n)'],
      ['disclosure_log', '(i18n)'],
      ['home_page', ''],
      ['tag_string', '(tags separated by spaces)'],
    ]

    expect(PublicBody.csv_import_fields).to eq(expected_fields)
  end

  it 'allows you to override the default list of fields to import' do
    old_csv_import_fields = PublicBody.csv_import_fields.clone
    expected_fields = [
      ['name', '(i18n)<strong>Existing records cannot be renamed</strong>'],
      ['short_name', '(i18n)'],
    ]

    PublicBody.csv_import_fields = expected_fields

    expect(PublicBody.csv_import_fields).to eq(expected_fields)

    # Reset our change so that we don't affect other specs
    PublicBody.csv_import_fields = old_csv_import_fields
  end

  it 'allows you to append to the default list of fields to import' do
    old_csv_import_fields = PublicBody.csv_import_fields.clone
    expected_fields = [
      ['name', '(i18n)<strong>Existing records cannot be renamed</strong>'],
      ['short_name', '(i18n)'],
      ['request_email', '(i18n)'],
      ['notes', '(i18n)'],
      ['publication_scheme', '(i18n)'],
      ['disclosure_log', '(i18n)'],
      ['home_page', ''],
      ['tag_string', '(tags separated by spaces)'],
      ['a_new_field', ''],
    ]

    PublicBody.csv_import_fields << ['a_new_field', '']

    expect(PublicBody.csv_import_fields).to eq(expected_fields)

    # Reset our change so that we don't affect other specs
    PublicBody.csv_import_fields = old_csv_import_fields
  end

  it "should import translations for fields whose values are the same as the default locale's" do
    original_count = PublicBody.count

    csv_contents = load_file_fixture("multiple-locales-same-name.csv")

    errors, notes = PublicBody.import_csv(csv_contents, '', 'replace', true, 'someadmin', ['en', 'es']) # true means dry run
    expect(errors).to eq([])
    expect(notes.size).to eq(3)
    expect(notes[0..1]).to eq([
      "line 2: creating new authority 'Test' (locale: en):\n\t{\"name\":\"Test\",\"request_email\":\"test@test.es\",\"home_page\":\"http://www.test.es/\",\"tag_string\":\"37\"}",
      "line 2: creating new authority 'Test' (locale: es):\n\t{\"name\":\"Test\"}",
    ])
    expect(notes[2]).to match(/Notes: Some  bodies are in database, but not in CSV file:\n(    .+\n)*You may want to delete them manually.\n/)

    expect(PublicBody.count).to eq(original_count)
  end
end

RSpec.describe PublicBody do
  let(:public_body) { FactoryBot.build(:public_body) }
  let(:legislation) { double(:legislation) }
  let(:legislations) { [legislation] }

  describe '#legislations' do
    subject { public_body.legislations }

    it 'pass self to Legislation.for_public_body' do
      expect(Legislation).to receive(:for_public_body).with(public_body).
        and_return(legislations)
      is_expected.to eq legislations
    end
  end

  describe '#legislation' do
    subject { public_body.legislation }

    it 'returns first legislations' do
      allow(public_body).to receive(:legislations).and_return(legislations)
      is_expected.to eq legislation
    end
  end
end

RSpec.describe PublicBody do

  describe "calculated home page" do
    it "should return the home page verbatim if it's present" do
      public_body = PublicBody.new
      public_body.home_page = "http://www.example.com"
      expect(public_body.calculated_home_page).to eq("http://www.example.com")
    end

    it "should return the home page based on the request email domain if it has one" do
      public_body = PublicBody.new
      allow(public_body).to receive(:request_email_domain).and_return "public-authority.com"
      expect(public_body.calculated_home_page).to eq("http://www.public-authority.com")
    end

    it "should return nil if there's no home page and the email domain can't be worked out" do
      public_body = PublicBody.new
      allow(public_body).to receive(:request_email_domain).and_return nil
      expect(public_body.calculated_home_page).to be_nil
    end

    it "should ensure home page URLs start with http://" do
      public_body = PublicBody.new
      public_body.home_page = "example.com"
      expect(public_body.calculated_home_page).to eq("http://example.com")
    end

    it "should not add http when https is present" do
      public_body = PublicBody.new
      public_body.home_page = "https://example.com"
      expect(public_body.calculated_home_page).to eq("https://example.com")
    end
  end

  describe 'when asked for notes without html' do

    before do
      @public_body = PublicBody.new(:notes => 'some <a href="/notes">notes</a>')
    end

    it 'should remove simple tags from notes' do
      expect(@public_body.notes_without_html).to eq('some notes')
    end

  end

  describe '#site_administration?' do

    it 'is true when the body has the site_administration tag' do
      p = FactoryBot.build(:public_body, :tag_string => 'site_administration')
      expect(p.site_administration?).to be true
    end

    it 'is false when the body does not have the site_administration tag' do
      p = FactoryBot.build(:public_body)
      expect(p.site_administration?).to be false
    end

  end

  describe '#has_request_email?' do

    before do
      @body = PublicBody.new(:request_email => 'test@example.com')
    end

    it 'should return false if request_email is nil' do
      @body.request_email = nil
      expect(@body.has_request_email?).to eq(false)
    end

    it 'should return false if the request email is "blank"' do
      @body.request_email = 'blank'
      expect(@body.has_request_email?).to eq(false)
    end

    it 'should return false if the request email is an empty string' do
      @body.request_email = ''
      expect(@body.has_request_email?).to eq(false)
    end

    it 'should return true if the request email is an email address' do
      expect(@body.has_request_email?).to eq(true)
    end
  end

  describe '#special_not_requestable_reason' do

    before do
      @body = PublicBody.new
    end

    it 'should return true if the body is defunct' do
      allow(@body).to receive(:defunct?).and_return(true)
      expect(@body.special_not_requestable_reason?).to eq(true)
    end

    it 'should return true if FOI does not apply' do
      allow(@body).to receive(:not_apply?).and_return(true)
      expect(@body.special_not_requestable_reason?).to eq(true)
    end

    it 'should return false if the body is not defunct and FOI applies' do
      expect(@body.special_not_requestable_reason?).to eq(false)
    end
  end

end

RSpec.describe PublicBody, " when override all public body request emails set" do
  it "should return the overridden request email" do
    expect(AlaveteliConfiguration).to receive(:override_all_public_body_request_emails).twice.and_return("catch_all_test_email@foo.com")
    @geraldine = public_bodies(:geraldine_public_body)
    expect(@geraldine.request_email).to eq("catch_all_test_email@foo.com")
  end
end

RSpec.describe PublicBody, "when calculating statistics" do
  it "should not include hidden requests in totals" do
    with_hidden_and_successful_requests do
      totals_data = PublicBody.get_request_totals(n=3,
                                                  highest=true,
                                                  minimum_requests=1)

      expect(totals_data['public_bodies'][-1].name).to eq("Geraldine Quango")
      expect(totals_data['totals'][-1]).to eq(3)
    end
  end

  it "should not include unclassified or hidden requests in percentages" do
    with_hidden_and_successful_requests do
      # For percentages don't include the hidden or
      # unclassified requests.  So, for the Geraldine Quango
      # we've made sure that there are only two visible and
      # classified requests, one of which is successful, so the
      # percentage should be 50%:

      percentages_data = PublicBody.get_request_percentages(column='info_requests_successful_count',
                                                            n=3,
                                                            highest=false,
                                                            minimum_requests=1)
      geraldine_index = percentages_data['public_bodies'].index do |pb|
        pb.name == "Geraldine Quango"
      end

      expect(percentages_data['y_values'][geraldine_index]).to eq(50)
    end
  end

  it "should only return totals for those with at least a minimum number of requests" do
    minimum_requests = 1
    with_enough_info_requests = PublicBody.where(["info_requests_count >= ?",
                                                  minimum_requests]).length
    all_data = PublicBody.get_request_totals 4, true, minimum_requests
    expect(all_data['public_bodies'].length).to eq(with_enough_info_requests)
  end

  it "should only return percentages for those with at least a minimum number of requests" do
    with_hidden_and_successful_requests do
      # With minimum requests at 3, this should return nil
      # (corresponding to zero public bodies) since the only
      # public body with just more than 3 info requests (The
      # Geraldine Quango) has a hidden and an unclassified
      # request within this block:
      minimum_requests = 3
      with_enough_info_requests = PublicBody.where(["info_requests_visible_classified_count >= ?",
                                                    minimum_requests]).length
      all_data = PublicBody.get_request_percentages(column='info_requests_successful_count',
                                                    n=10,
                                                    true,
                                                    minimum_requests)
      expect(all_data).to be_nil
    end
  end

  it "should only return those with at least a minimum number of requests, but not tagged 'test'" do
    hpb = PublicBody.find_by_name 'Department for Humpadinking'

    original_tag_string = hpb.tag_string
    hpb.add_tag_if_not_already_present 'test'

    begin
      minimum_requests = 1
      with_enough_info_requests = PublicBody.where(["info_requests_count >= ?", minimum_requests])
      all_data = PublicBody.get_request_totals 4, true, minimum_requests
      expect(all_data['public_bodies'].length).to eq(3)
    ensure
      hpb.tag_string = original_tag_string
    end
  end

end

RSpec.describe PublicBody, 'when asked for popular bodies' do

  it 'should return bodies correctly when passed the hyphenated version of the locale' do
    allow(AlaveteliConfiguration).to receive(:frontpage_publicbody_examples).and_return('')
    expect(PublicBody.popular_bodies('he-IL')).to eq([public_bodies(:humpadink_public_body)])
  end

  it 'returns example bodies if some are specified' do
    allow(AlaveteliConfiguration).to receive(:frontpage_publicbody_examples).and_return('tgq')
    expect(PublicBody.popular_bodies('en')).to eq([public_bodies(:geraldine_public_body)])
  end

end

RSpec.describe PublicBody do

  describe '.foi_applies' do
    subject { PublicBody.foi_applies }

    let!(:public_body) { FactoryBot.create(:public_body) }
    let!(:not_apply_body) { FactoryBot.create(:public_body, :not_apply) }

    it 'include active bodies' do
      is_expected.to include(public_body)
    end

    it 'does not include bodies where FOI/EIR is not applicable' do
      is_expected.to_not include(not_apply_body)
    end

  end

  describe '.not_defunct' do
    subject { PublicBody.not_defunct }

    let!(:public_body) { FactoryBot.create(:public_body) }
    let!(:defunct_body) { FactoryBot.create(:public_body, :defunct) }

    it 'include active bodies' do
      is_expected.to include(public_body)
    end

    it 'does not include defunct bodies' do
      is_expected.to_not include(defunct_body)
    end

  end

  describe '#is_requestable?' do

    before do
      @body = PublicBody.new(:request_email => 'test@example.com')
    end

    it 'should return false if the body is defunct' do
      allow(@body).to receive(:defunct?).and_return true
      expect(@body.is_requestable?).to eq(false)
    end

    it 'should return false if FOI does not apply' do
      allow(@body).to receive(:not_apply?).and_return true
      expect(@body.is_requestable?).to eq(false)
    end

    it 'should return false there is no request_email' do
      allow(@body).to receive(:has_request_email?).and_return false
      expect(@body.is_requestable?).to eq(false)
    end

    it 'returns true if not subject to FOI law' do
      allow(@body).to receive(:not_subject_to_law?).and_return true
      expect(@body.is_requestable?).to eq(true)
    end

    it 'should return true if the request email is an email address' do
      expect(@body.is_requestable?).to eq(true)
    end

  end

  describe '.is_requestable' do
    subject { PublicBody.is_requestable }

    let!(:public_body) { FactoryBot.create(:public_body) }
    let!(:blank_body) { FactoryBot.create(:blank_email_public_body) }
    let!(:defunct_body) { FactoryBot.create(:public_body, :defunct) }
    let!(:not_apply_body) { FactoryBot.create(:public_body, :not_apply) }

    it 'includes return requestable body' do
      is_expected.to include(public_body)
    end

    it 'does not include bodies without request email' do
      is_expected.to_not include(blank_body)
    end

    it 'does not include defunct bodies' do
      is_expected.to_not include(defunct_body)
    end

    it 'does not include bodies where FOI/EIR is not applicable' do
      is_expected.to_not include(not_apply_body)
    end

  end

  describe '#is_followupable?' do

    before do
      @body = PublicBody.new(:request_email => 'test@example.com')
    end

    it 'should return false there is no request_email' do
      allow(@body).to receive(:has_request_email?).and_return false
      expect(@body.is_followupable?).to eq(false)
    end

    it 'should return true if the request email is an email address' do
      expect(@body.is_followupable?).to eq(true)
    end

  end

  describe '#not_requestable_reason' do

    before do
      @body = PublicBody.new(:request_email => 'test@example.com')
    end

    it 'should return "defunct" if the body is defunct' do
      allow(@body).to receive(:defunct?).and_return true
      expect(@body.not_requestable_reason).to eq('defunct')
    end

    it 'should return "not_apply" if FOI does not apply' do
      allow(@body).to receive(:not_apply?).and_return true
      expect(@body.not_requestable_reason).to eq('not_apply')
    end


    it 'should return "bad_contact" there is no request_email' do
      allow(@body).to receive(:has_request_email?).and_return false
      expect(@body.not_requestable_reason).to eq('bad_contact')
    end

    it 'should raise an error if the body is not defunct, FOI applies and has an email address' do
      expected_error = "not_requestable_reason called with type that has no reason"
      expect { @body.not_requestable_reason }.to raise_error(expected_error)
    end

  end

  describe '#update_counter_cache' do
    let(:public_body) { FactoryBot.create(:public_body) }
    let(:tmp_body) { FactoryBot.create(:public_body) }

    it 'does not create a new version of the authority' do
      expect { public_body.update_counter_cache }.
        not_to change { public_body.versions.count }
    end

    it 'does not mark the authority for reindexing' do
      # Call public_body so that any unrelated indexing events are created
      # before we call update_counter_cache
      public_body.save!
      jobs = ActsAsXapian::ActsAsXapianJob.where(model: 'PublicBody')
      expect { public_body.update_counter_cache }.not_to change { jobs.count }
    end

    it 'does not touch updated_at' do
      expect { public_body.update_counter_cache }.
        not_to change { public_body.updated_at }
    end

    it 'increments info_requests_not_held_count' do
      request = FactoryBot.create(:not_held_request)
      request.update_column(:public_body_id, public_body.id)
      expect { public_body.update_counter_cache }.
        to change { public_body.info_requests_not_held_count }.from(nil).to(1)
    end

    it 'decrements info_requests_not_held_count' do
      request = FactoryBot.create(:not_held_request, public_body: public_body)
      public_body.update_counter_cache
      request.update_column(:public_body_id, tmp_body.id)

      expect { public_body.update_counter_cache }.
        to change { public_body.info_requests_not_held_count }.from(1).to(0)
    end

    it 'increments info_requests_successful_count' do
      request = FactoryBot.create(:successful_request)
      request.update_column(:public_body_id, public_body.id)
      expect { public_body.update_counter_cache }.
        to change { public_body.info_requests_successful_count }.from(nil).to(1)
    end

    it 'decrements info_requests_successful_count' do
      request =
        FactoryBot.create(:successful_request, public_body: public_body)
      public_body.update_counter_cache
      request.update_column(:public_body_id, tmp_body.id)

      expect { public_body.update_counter_cache }.
        to change { public_body.info_requests_successful_count }.from(1).to(0)
    end

    it 'increments info_requests_visible_classified_count' do
      request = FactoryBot.create(:info_request)
      request.update_column(:public_body_id, public_body.id)
      expect { public_body.update_counter_cache }.
        to change { public_body.info_requests_visible_classified_count }.
        from(nil).to(1)
    end

    it 'decrements info_requests_visible_classified_count' do
      request = FactoryBot.create(:info_request, public_body: public_body)
      public_body.update_counter_cache
      request.update_column(:public_body_id, tmp_body.id)

      expect { public_body.update_counter_cache }.
        to change { public_body.info_requests_visible_classified_count }.
        from(1).to(0)
    end

    it 'increments info_requests_visible_count' do
      request = FactoryBot.create(:info_request, awaiting_description: true)
      request.update_column(:public_body_id, public_body.id)
      expect { public_body.update_counter_cache }.
        to change { public_body.info_requests_visible_count }.from(0).to(1)
    end

    it 'decrements info_requests_visible_count' do
      request = FactoryBot.create(:info_request, public_body: public_body,
                                                 awaiting_description: true)
      public_body.update_counter_cache
      request.update_column(:public_body_id, tmp_body.id)

      expect { public_body.update_counter_cache }.
        to change { public_body.info_requests_visible_count }.from(1).to(0)
    end
  end
end

RSpec.describe PublicBody::Translation do

  it 'requires a locale' do
    translation = PublicBody::Translation.new
    translation.valid?
    expect(translation.errors[:locale]).to eq(["can't be blank"])
  end

  it 'is valid if all required attributes are assigned' do
    translation = PublicBody::Translation.new(
      :locale => AlaveteliLocalization.default_locale
    )
    expect(translation).to be_valid
  end

end

RSpec.describe PublicBody::Version do
  let(:public_body) { FactoryBot.create(:public_body) }

  describe '#compare' do

    describe 'when no block is given' do

      describe 'when there is no other version' do

        it 'returns an empty list' do
          current = public_body.versions.latest
          expect(current.compare(current.previous)).to eq([])
        end

      end

      describe 'when there are no significant changes' do

        it 'returns an empty list' do
          public_body.last_edit_comment = 'Just tinkering'
          public_body.save!
          current = public_body.versions.latest
          expect(current.compare(current.previous)).to eq([])
        end

      end

      describe 'when there are significant changes' do

        it 'returns a list of changes as hashes with keys :name, :from and
           :to' do
          public_body.request_email = 'new@example.com'
          public_body.save!
          current = public_body.versions.latest
          expected = { :name => "Request email",
                       :from => "request@example.com",
                       :to => "new@example.com" }
          expect(current.compare(current.previous)).to eq([ expected ])
        end

      end

    end

    describe 'when no block is given' do

      describe 'when there is no other version' do

        it 'does not yield' do
          current = public_body.versions.latest
          expect { |b| current.compare(current.previous, &b) }.
            not_to yield_control
        end

      end

      describe 'when there are no significant changes' do

        it 'returns an empty list' do
          public_body.last_edit_comment = 'Just tinkering'
          public_body.save!
          current = public_body.versions.latest
          expect { |b| current.compare(current.previous, &b) }.
            not_to yield_control
        end

      end

      describe 'when there are significant changes' do

        it 'returns a list of changes as hashes with keys :name, :from and
           :to' do
          public_body.request_email = 'new@example.com'
          public_body.save!
          current = public_body.versions.latest
          expected = { :name => "Request email",
                       :from => "request@example.com",
                       :to => "new@example.com" }
          expect { |b| current.compare(current.previous, &b) }.
            to yield_with_args(expected)
        end

      end

    end

  end

end

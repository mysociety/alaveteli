# == Schema Information
#
# Table name: users
#
#  id                                :integer          not null, primary key
#  email                             :string           not null
#  name                              :string           not null
#  hashed_password                   :string           not null
#  salt                              :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  email_confirmed                   :boolean          default(FALSE), not null
#  url_name                          :text             not null
#  last_daily_track_email            :datetime
#  ban_text                          :text             default(""), not null
#  about_me                          :text             default(""), not null
#  locale                            :string
#  email_bounced_at                  :datetime
#  email_bounce_message              :text             default(""), not null
#  no_limit                          :boolean          default(FALSE), not null
#  receive_email_alerts              :boolean          default(TRUE), not null
#  can_make_batch_requests           :boolean          default(FALSE), not null
#  otp_enabled                       :boolean          default(FALSE), not null
#  otp_secret_key                    :string
#  otp_counter                       :integer          default(1)
#  confirmed_not_spam                :boolean          default(FALSE), not null
#  comments_count                    :integer          default(0), not null
#  info_requests_count               :integer          default(0), not null
#  track_things_count                :integer          default(0), not null
#  request_classifications_count     :integer          default(0), not null
#  public_body_change_requests_count :integer          default(0), not null
#  info_request_batches_count        :integer          default(0), not null
#  daily_summary_hour                :integer
#  daily_summary_minute              :integer
#  closed_at                         :datetime
#  login_token                       :string
#  receive_user_messages             :boolean          default(TRUE), not null
#  user_messages_count               :integer          default(0), not null
#  status_update_count               :integer          default(0), not null
#  last_sign_in_at                   :datetime
#

require 'spec_helper'
require 'models/user/spreadable_alerts'
require 'models/concerns/taggable'

RSpec.describe User do
  it_behaves_like 'PhaseCounts'
  it_behaves_like 'user/spreadable_alerts'
  it_behaves_like 'concerns/taggable', :user
end

RSpec.describe User, 'associations' do
  let(:user) { FactoryBot.create(:user) }
  let(:project1) { FactoryBot.create(:project, owner: user) }
  let(:project2) { FactoryBot.create(:project) }

  before do
    project2.contributors << user
    project2.save
  end

  it 'has many projects' do
    expect(user.projects).to match_array([project1, project2])
  end

  it 'has many projects where the user is the owner' do
    expect(user.projects.owner).to match_array([project1])
  end

  it 'has many projects where the user is a contributor' do
    expect(user.projects.contributor).to match_array([project2])
  end
end

RSpec.describe User, "making up the URL name" do
  before do
    @user = User.new
  end

  it 'should remove spaces, and make lower case' do
    @user.name = 'Some Name'
    @user.valid?
    expect(@user.url_name).to eq('some_name')
  end

  it 'should not allow a numeric name' do
    @user.name = '1234'
    @user.valid?
    expect(@user.url_name).to eq('user')
  end
end

RSpec.describe User, "banning the user" do
  it 'does not change the URL name' do
    user = FactoryBot.create(:user, name: 'nasty user 123')
    user.update(ban_text: 'You are banned')
    expect(user.url_name).to eq('nasty_user_123')
  end

  it 'does not change the stored name' do
    user = FactoryBot.create(:user, name: 'nasty user 123')
    user.update(ban_text: 'You are banned')
    expect(user.read_attribute(:name)).to eq('nasty user 123')
  end

  it 'appends a message to the name' do
    user = FactoryBot.build(:user, name: 'nasty user', ban_text: 'banned')
    expect(user.name).to eq('nasty user (Account suspended)')
  end
end

RSpec.describe User, "showing the name" do
  before do
    @user = User.new
    @user.name = 'Some Name '
  end

  it 'should strip whitespace' do
    expect(@user.name).to eq('Some Name')
  end

  describe 'if user has been banned' do
    before do
      @user.ban_text = "Naughty user"
    end

    it 'should show an "Account suspended" suffix' do
      expect(@user.name).to eq('Some Name (Account suspended)')
    end
  end
end

RSpec.describe User, 'password hashing algorithms' do
  def create_user(options = {})
    User.create(options.merge(
      name: 'User',
      email: 'user@localhost'
    ))
  end

  let(:found_user) do
    User.authenticate_from_form(
      email: 'user@localhost', password: 'jonespassword'
    )
  end

  context 'password hashed with SHA1' do
    let!(:user) do
      create_user(
        # object_id.to_s + rand.to_s
        salt: '701486499852200.07409853368152741',
        # Digest::SHA1.hexdigest('jonespassword' + self.salt)
        hashed_password: '8dc6e4d82ee61a3a1724e9f5053e1bef892dc3ca'
      )
    end

    it 'should find the user when given the right email and password' do
      expect(found_user.errors.size).to eq(0)
      expect(found_user).to eq(user)
    end

    it 'updates hashed password with bcrypt version' do
      expect(found_user.hashed_password).to match(/^\$2[ayb]\$.{56}$/)
    end

    it 'returns user in sha1 scope' do
      expect(User.sha1).to include user
    end
  end

  context 'short password hashed with SHA1' do
    let!(:user) do
      create_user(
        # object_id.to_s + rand.to_s
        salt: '702047220705400.701827131831902',
        # Digest::SHA1.hexdigest('tooshort' + self.salt)
        hashed_password: '4eb8c1a455e2e04c9fe70cc07c8830a9d18dde97'
      )
    end

    it 'does not validate password length and updates password' do
      user.has_this_password?('tooshort')
      expect(user.errors).to be_empty
      expect(user.hashed_password).to match(/^\$2[ayb]\$.{56}$/)
    end

    it 'does not upgrade password if other attribute changes have been made' do
      user.name = 'Changed User'
      user.has_this_password?('tooshort')
      expect(user.errors).to be_empty
      expect(user.hashed_password).to_not match(/^\$2[ayb]\$.{56}$/)
    end

    it 'returns user in sha1 scope' do
      expect(User.sha1).to include user
    end
  end

  context 'password hashed with SHA1 and then bcrypt' do
    let!(:user) do
      create_user(
        # object_id.to_s + rand.to_s
        salt: '701486609569600.08392293204545553',
        # BCrypt::Password.create(
        #   Digest::SHA1.hexdigest('jonespassword' + self.salt)
        # )
        hashed_password:
          '$2a$10$rNWVOXDmMZDlLz.6InmE1.7NvD7vp2KQ5iFSVSuXUVDcw0QzmLfO.'
      )
    end

    it 'should find the user when given the right email and password' do
      expect(found_user.errors.size).to eq(0)
      expect(found_user).to eq(user)
    end

    it 'updates hashed password with bcrypt version' do
      expect(found_user.hashed_password).to match(/^\$2[ayb]\$.{56}$/)
    end

    it 'does not return user in sha1 scope' do
      expect(User.sha1).to_not include user
    end
  end

  context 'password hashed with bcrypt' do
    let!(:user) do
      create_user(
        # BCrypt::Password.create('jonespassword')
        hashed_password:
          '$2a$10$f8RWgVTYJ.gc/wwINMYIfeHayceTNALtTgVP0xrVrnVFbcCCgpT7C'
      )
    end

    it 'should find the user when given the right email and password' do
      expect(found_user.errors.size).to eq(0)
      expect(found_user).to eq(user)
    end

    it 'does not return user in sha1 scope' do
      expect(User.sha1).to_not include user
    end
  end
end

RSpec.describe User, 'when saving' do
  before do
    @user = User.new
  end

  it 'should not save without setting some parameters' do
    expect { @user.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'should not save with misformatted email' do
    @user.email = 'mousefooble'
    expect(@user).to_not be_valid
    expect(@user.errors[:email].size).to eq(1)
  end

  it 'should not allow an email address as a name' do
    @user.name = 'silly@example.com'
    @user.email = 'silly@example.com'
    expect(@user).to_not be_valid
    expect(@user.errors[:name].size).to eq(1)
  end

  it 'should not save with no password' do
    @user.password = ''
    expect(@user).to_not be_valid
    expect(@user.errors[:password].size).to eq(1)
  end

  it 'should not save with too short password' do
    @user.password = 'a' * 11
    expect(@user).to_not be_valid
    expect(@user.errors[:password].size).to eq(1)
  end

  it 'should not save with too long password' do
    @user.password = 'a' * 73
    expect(@user).to_not be_valid
    expect(@user.errors[:password].size).to eq(1)
  end

  it 'should not save with wrong password confirmation' do
    @user.password = 'a' * 12
    @user.password_confirmation = 'b' * 12
    expect(@user).to_not be_valid
    expect(@user.errors[:password_confirmation].size).to eq(1)
  end

  it 'does not allow a long about_me' do
    @user.about_me = 'a' * 501
    expect(@user).to_not be_valid
    expect(@user.errors[:about_me].size).to eq(1)
  end

  it 'should save with reasonable name, password and email' do
    @user.name = 'Mr. Reasonable'
    @user.password = 'insecurepassword'
    @user.password_confirmation = 'insecurepassword'
    @user.email = 'reasonable@localhost'
    @user.save!
    expect(@user).to be_valid
  end

  it 'should let you make two users with same name' do
    @user.name = 'Mr. Flobble'
    @user.password = 'insecurepassword'
    @user.email = 'flobble@localhost'
    @user.save!
    expect(@user).to be_valid

    @user2 = User.new
    @user2.name = 'Mr. Flobble'
    @user2.password = 'insecurepassword'
    @user2.email = 'flobble2@localhost'
    @user2.save!
    expect(@user2).to be_valid
  end

  it 'should not let you make two users with same email' do
    @user.name = 'Mr. Flobble'
    @user.password = 'insecurepassword'
    @user.email = 'flobble@localhost'
    @user.save!
    expect(@user).to be_valid

    @user2 = User.new
    @user2.name = 'Flobble Jr.'
    @user2.password = 'insecurepassword'
    @user2.email = 'flobble@localhost'
    expect(@user2).to_not be_valid
    expect(@user2.errors[:email].size).to eq(1)
    expect(@user2.errors[:email][0]).to eq('This email is already in use')

    # should ignore case differences
    @user2.email = 'FloBBle@localhost'
    expect(@user2).to_not be_valid
    expect(@user2.errors[:email].size).to eq(1)
    expect(@user2.errors[:email][0]).to eq('This email is already in use')
  end

  it 'should allow updated attributes even if old password is invalid' do
    @user.name = 'Mr. Elderly'
    @user.password = 'invalid'
    @user.email = 'elderly@localhost'
    @user.save(validate: false)

    @user = User.find_by(email: 'elderly@localhost')
    @user.name = 'Mr. Young'
    @user.email = 'young@localhost'
    @user.save!
    expect(@user).to be_valid
  end

  it 'should mark the model for reindexing in xapian if the no_xapian_reindex flag is set to false' do
    @user.name = 'Mr. First'
    @user.password = 'insecurepassword'
    @user.email = 'reasonable@localhost'
    @user.no_xapian_reindex = false
    expect(@user).to receive(:xapian_mark_needs_index)
    @user.save!
  end

  it 'should mark the model for reindexing in xapian if the no_xapian_reindex flag is not set' do
    @user.name = 'Mr. Second'
    @user.password = 'insecurepassword'
    @user.email = 'reasonable@localhost'
    @user.no_xapian_reindex = nil
    expect(@user).to receive(:xapian_mark_needs_index)
    @user.save!
  end

  it 'should not mark the model for reindexing in xapian if the no_xapian_reindex flag is set' do
    @user.name = 'Mr. Third'
    @user.password = 'insecurepassword'
    @user.email = 'reasonable@localhost'
    @user.no_xapian_reindex = true
    expect(@user).not_to receive(:xapian_mark_needs_index)
    @user.save!
  end
end

RSpec.describe User, "when reindexing referencing models" do
  let(:user) { FactoryBot.create(:user) }
  let!(:comment) { FactoryBot.create(:comment, :with_event, user: user) }
  let(:comment_event) { comment.reload.info_request_events.last }
  let(:request) { FactoryBot.create(:info_request, user: user) }
  let(:request_event) { request.reload.last_event }

  it 'triggers cache invalidation when updated' do
    expect(NotifyCacheJob).to receive(:perform_later).with(user)
    user.save!
  end

  it "should reindex events associated with that user's comments when URL changes" do
    user.url_name = 'updated_url_name'
    user.save!

    query = { model: 'InfoRequestEvent',
              model_id: comment_event.id,
              action: 'update' }

    expect(ActsAsXapian::ActsAsXapianJob.where(query).exists?).to eq(true)
  end

  it "should reindex events associated with that user's requests when URL changes" do
    user.url_name = 'updated_url_name'
    user.save!

    query = { model: 'InfoRequestEvent',
              model_id: request_event.id,
              action: 'update' }

    expect(ActsAsXapian::ActsAsXapianJob.where(query).exists?).to eq(true)
  end

  describe 'when no_xapian_reindex is set' do
    before do
      user.no_xapian_reindex = true
    end

    it 'should not reindex events associated with that user\'s comments when URL changes' do
      expect(comment_event).to_not receive(:xapian_mark_needs_index)
      user.url_name = 'updated_url_name'
      user.save!
    end

    it 'should not reindex events associated with that user\'s requests when URL changes' do
      expect(request_event).to_not receive(:xapian_mark_needs_index)
      user.url_name = 'updated_url_name'
      user.save!
    end
  end
end

RSpec.describe User, "when checking abilities" do
  before do
    @user = users(:bob_smith_user)
  end

  it "should not get admin links" do
    expect(@user.admin_page_links?).to be false
  end

  it "should not exceed limits" do
    expect(@user.exceeded_request_limits?).to be false
    expect(@user.exceeded_followup_limits?).to be false
    expect(@user.exceeded_comment_limits?).to be false
    expect(@user.exceeded_user_message_limits?).to be false
  end
end

RSpec.describe User, 'previous names' do
  let(:user) { FactoryBot.build(:user, name: 'Robert') }

  let(:outgoing_message_1) do
    FactoryBot.build(:initial_request, from_name: 'Bobby', user: user)
  end

  let(:followup_1) do
    FactoryBot.build(:new_information_followup, from_name: 'Bob', user: user)
  end

  let(:followup_2) do
    FactoryBot.build(:new_information_followup, from_name: 'Bob', user: user)
  end

  let(:outgoing_message_2) do
    FactoryBot.build(:initial_request, from_name: 'Robert', user: user)
  end

  before do
    FactoryBot.create(:sent_event, outgoing_message: outgoing_message_1)
    FactoryBot.create(:followup_sent_event, outgoing_message: followup_1)
    FactoryBot.create(:followup_sent_event, outgoing_message: followup_2)
    FactoryBot.create(:sent_event, outgoing_message: outgoing_message_2)
  end

  describe '#previous_names' do
    it 'returns unique previous names without current name' do
      expect(user.previous_names).to include('Bobby').once # previous name
      expect(user.previous_names).to include('Bob').once # previous name
      expect(user.previous_names).to_not include('Robert') # current name
    end
  end

  describe '#safe_previous_names' do
    it 'returns unique safe previous names without current name' do
      FactoryBot.create(
        :censor_rule, user: user, text: 'Bobby', replacement: '[redacted]'
      )

      expect(user.safe_previous_names).to include('[redacted]').once
      expect(user.safe_previous_names).to include('Bob').once # previous name
      expect(user.safe_previous_names).to_not include('Robert') # current name
    end
  end
end

RSpec.describe User, " when making name and email address" do
  it "should generate a name and email" do
    @user = User.new
    @user.name = "Sensible User"
    @user.email = "sensible@localhost"

    expect(@user.name_and_email).to eq("Sensible User <sensible@localhost>")
  end

  it "should quote name and email with funny characters in the name" do
    @user = User.new
    @user.name = "Silly @ User"
    @user.email = "silly@localhost"

    expect(@user.name_and_email).to eq("\"Silly @ User\" <silly@localhost>")
  end
end

# TODO: not finished
RSpec.describe User, "when setting a profile photo" do
  before do
    @user = User.new
    @user.name = "Sensible User"
    @user.email = "sensible@localhost"
    @user.password = "sensiblepassword"
  end

  it "should attach it to the user" do
    data = load_file_fixture("parrot.png")
    profile_photo = ProfilePhoto.new(data: data)
    @user.set_profile_photo(profile_photo)
    expect(profile_photo.user).to eq(@user)
  end

  #    it "should destroy old photos being replaced" do
  #        ProfilePhoto.count.should == 0
  #
  #        data_1 = load_file_fixture("parrot.png")
  #        profile_photo_1 = ProfilePhoto.new(:data => data_1)
  #        data_2 = load_file_fixture("parrot.jpg")
  #        profile_photo_2 = ProfilePhoto.new(:data => data_2)
  #
  #        @user.set_profile_photo(profile_photo_1)
  #        @user.save!
  #        ProfilePhoto.count.should == 1
  #        @user.set_profile_photo(profile_photo_2)
  #        @user.save!
  #        ProfilePhoto.count.should == 1
  #    end
end

RSpec.describe User, '#should_be_emailed?' do
  context 'when confirmed and active' do
    let(:user) { FactoryBot.build(:user) }
    before { allow(user).to receive(:active?).and_return(true) }

    it 'should be emailed' do
      expect(user).to be_should_be_emailed
    end
  end

  context 'when confirmed and inactive' do
    let(:user) { FactoryBot.build(:user) }
    before { allow(user).to receive(:active?).and_return(false) }

    it 'should not be emailed' do
      expect(user).to_not be_should_be_emailed
    end
  end

  context 'when confirmed and unsubscribed' do
    let(:user) { FactoryBot.build(:user, receive_email_alerts: false) }

    it 'should not be emailed' do
      expect(user).to_not be_should_be_emailed
    end
  end

  context 'when unconfirmed and active' do
    let(:user) { FactoryBot.build(:unconfirmed_user) }
    before { allow(user).to receive(:active?).and_return(true) }

    it 'should not be emailed' do
      expect(user).to_not be_should_be_emailed
    end
  end

  context 'when unconfirmed and inactive' do
    let(:user) { FactoryBot.build(:unconfirmed_user) }
    before { allow(user).to receive(:active?).and_return(false) }

    it 'should not be emailed' do
      expect(user).to_not be_should_be_emailed
    end
  end
end

RSpec.describe User, "when emails have bounced" do
  it "should record bounces" do
    User.record_bounce_for_email("bob@localhost", "A bounce message")

    user = User.find_user_by_email("bob@localhost")
    expect(user.email_bounced_at).not_to be_nil
    expect(user.email_bounce_message).to eq("A bounce message")
  end

  it 'records valid UTF-8 for a bounce message with invalid UTF-8' do
    User.record_bounce_for_email("bob@localhost", "Invalid utf-8 \x96")
    user = User.find_user_by_email("bob@localhost")
    expect(user.email_bounce_message).to eq("Invalid utf-8 –")
  end
end

RSpec.describe User do
  describe '.search' do
    subject { described_class.search(query) }

    let(:user_1) do
      attrs = { name: 'Alice', email: 'alice@example.com', about_me: 'foo bar' }
      FactoryBot.create(:user, attrs)
    end

    let(:user_2) do
      attrs = { name: 'James', email: 'james@example.com', about_me: 'bar' }
      FactoryBot.create(:user, attrs)
    end

    context 'when given a name' do
      let(:query) { 'Alice' }
      it { is_expected.to match_array([user_1]) }
    end

    context 'when given a partial name' do
      let(:query) { 'lic' }
      it { is_expected.to match_array([user_1]) }
    end

    context 'when given an email' do
      let(:query) { 'alice@example.com' }
      it { is_expected.to match_array([user_1]) }
    end

    context 'when given a partial email' do
      let(:query) { 'alice@' }
      it { is_expected.to match_array([user_1]) }
    end

    context 'when given an about_me matching a single user' do
      let(:query) { 'foo' }
      it { is_expected.to match_array([user_1]) }
    end

    context 'when given an about_me matching multiple users' do
      let(:query) { 'bar' }
      it { is_expected.to match_array([user_1, user_2]) }
    end
  end

  describe '.authenticate_from_form' do
    let(:empty_user) { described_class.new }

    let!(:full_user) do
      FactoryBot.create(:user, name: 'Sensible User',
                               password: 'foolishpassword',
                               email: 'sensible@localhost')
    end

    let(:wrong_password_attrs) do
      { email: 'sensible@localhost', password: 'iownzyou' }
    end

    let(:wrong_email_attrs) do
      { email: 'soccer@localhost', password: 'foolishpassword' }
    end

    let(:correct_attrs) do
      { email: 'sensible@localhost', password: 'foolishpassword' }
    end

    it 'has errors when given the wrong password' do
      found_user = User.authenticate_from_form(wrong_password_attrs)
      expect(found_user.errors.size).to be > 0
    end

    it 'does not find the user when given the wrong email' do
      found_user = User.authenticate_from_form(wrong_email_attrs)
      expect(found_user.errors.size).to be > 0
    end

    it 'does not find closed user accounts' do
      full_user.update!(closed_at: Time.zone.now)
      found_user = User.authenticate_from_form(correct_attrs)
      expect(found_user.errors[:base]).to eq(['This account has been closed.'])
    end

    it 'does not reveal closed user accounts with an incorrect password' do
      full_user.update!(closed_at: Time.zone.now)
      found_user = User.authenticate_from_form(wrong_password_attrs)
      expect(found_user.errors[:base].join).to match(/please try again/)
    end

    it 'returns the user with no errors when given the correct email and password' do
      found_user = User.authenticate_from_form(correct_attrs)
      expect(found_user.errors.size).to eq(0)
      expect(found_user).to eq(full_user)
    end
  end

  describe '.authenticate_from_session' do
    let(:user) { FactoryBot.create(:user) }

    it 'finds a user by ID and login token' do
      session = { user_id: user.id, user_login_token: user.login_token }
      expect(User.authenticate_from_session(session)).to eq(user)
    end

    it 'returns nil without user_id session' do
      session = { user_id: nil }
      expect(User.authenticate_from_session(session)).to be_nil
    end

    it "returns nil when user ID doesn't match" do
      session = { user_id: 1, user_login_token: user.login_token }
      expect(User.authenticate_from_session(session)).to be_nil
    end

    it "returns nil when user login token doesn't match" do
      session = { user_id: user.id, user_login_token: 'ABC' }
      expect(User.authenticate_from_session(session)).to be_nil
    end
  end

  describe '#stay_logged_in_on_redirect?' do
    it 'is true if the user is an admin' do
      admin = FactoryBot.create(:admin_user)
      expect(admin.stay_logged_in_on_redirect?).to eq(true)
    end

    it 'is false if the user is not an admin' do
      user = FactoryBot.create(:user)
      expect(user.stay_logged_in_on_redirect?).to eq(false)
    end
  end

  describe '#sign_ins' do
    subject { user.sign_ins }

    context 'sort order is most recent first' do
      let(:user) { FactoryBot.create(:user) }

      let!(:sign_ins) do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(1)
        FactoryBot.create_list(:user_sign_in, 2, user: user)
      end

      it { is_expected.to match_array(sign_ins.reverse) }
    end
  end

  describe '#locale' do
    subject { user.locale }

    context 'when the locale is set' do
      let(:user) { FactoryBot.build(:user, locale: 'fr') }
      it { is_expected.to eq('fr') }
    end

    context 'when the locale is empty' do
      let(:user) { FactoryBot.build(:user, locale: nil) }
      it { is_expected.to eq(AlaveteliLocalization.locale) }
    end
  end

  describe '.cached_urls' do
    it 'includes the correct paths' do
      user = FactoryBot.create(:user)
      expect(user.cached_urls).to eq(["/user/" + user.url_name])
    end
  end

  describe '#transactions' do
    it 'returns a TransactionCalculator with the default transaction set' do
      user = User.new
      expect(user.transactions).to eq(User::TransactionCalculator.new(user))
    end

    it 'returns a TransactionCalculator with a custom transaction set' do
      user = User.new
      calculator =
        User::TransactionCalculator.
          new(user, transaction_associations: [:comments, :info_requests])
      expect(user.transactions(:comments, :info_requests)).to eq(calculator)
    end
  end

  describe '#password=' do
    it 'creates a hashed password when the password is set' do
      expect(subject.hashed_password).to be_nil
      subject.password = "a test password"
      expect(subject.hashed_password).not_to be_nil
    end
  end

  describe '#destroy' do
    let(:user) { FactoryBot.create(:user) }

    it 'destroys any associated info_requests' do
      info_request = FactoryBot.create(:info_request)
      info_request.user.reload.destroy
      expect(InfoRequest.where(id: info_request.id)).to be_empty
    end

    it 'destroys any associated user_info_request_sent_alerts' do
      info_request = FactoryBot.create(:info_request)
      alert = user.user_info_request_sent_alerts.build(info_request: info_request,
                                                       alert_type: 'overdue_1')
      user.destroy
      expect(UserInfoRequestSentAlert.where(id: alert.id)).to be_empty
    end

    it 'destroys any associated post_redirects' do
      post_redirect = PostRedirect.create(uri: '/',
                                          user_id: user.id)
      user.destroy
      expect(PostRedirect.where(id: post_redirect.id)).to be_empty
    end

    it 'destroys any associated track_things' do
      track_thing = FactoryBot.create(:search_track)
      track_thing.tracking_user.destroy
      expect(TrackThing.where(id: track_thing.id)).to be_empty
    end

    it 'destroys any associated comments' do
      comment = FactoryBot.create(:comment)
      comment.user.destroy
      expect(Comment.where(id: comment.id)).to be_empty
    end

    it 'destroys any associated public_body_change_requests' do
      change_request = FactoryBot.create(:add_body_request)
      change_request.user.destroy
      expect(PublicBodyChangeRequest.where(id: change_request.id))
        .to be_empty
    end

    it 'destroys any associated profile_photos' do
      profile_photo = user.create_profile_photo(data: 'xxx')
      user.destroy
      expect(ProfilePhoto.where(id: profile_photo.id)).to be_empty
    end

    it 'destroys any associated censor_rules' do
      censor_rule = FactoryBot.create(:user_censor_rule)
      censor_rule.user.destroy
      expect(CensorRule.where(id: censor_rule.id)).to be_empty
    end

    it 'destroys any associated info_request_batches' do
      info_request_batch = FactoryBot.create(:info_request_batch)
      info_request_batch.user.destroy
      expect(InfoRequestBatch.where(id: info_request_batch.id)).to be_empty
    end

    it 'destroys any associated request_classifications' do
      request_classification = FactoryBot.create(:request_classification)
      request_classification.user.destroy
      expect(RequestClassification.where(id: request_classification.id))
        .to be_empty
    end
  end

  describe '#expire_requests' do
    it 'create expire job for the user' do
      user = FactoryBot.build(:user)
      expect(InfoRequestExpireJob).to receive(:perform_later).
        with(user, :info_requests)
      user.expire_requests
    end
  end

  describe '#expire_comments' do
    it 'calls reindex_request_events on all associated requests' do
      user = FactoryBot.build(:user)

      comment_1 = double(:comment)
      comment_2 = double(:comment)

      allow(user).to receive_message_chain(:comments, :find_each).
        and_yield(comment_1).and_yield(comment_2)

      expect(comment_1).to receive(:reindex_request_events)
      expect(comment_2).to receive(:reindex_request_events)

      user.expire_comments
    end
  end

  describe '#valid?' do
    context 'with require_otp' do
      it 'has no effect when otp is disabled' do
        user = FactoryBot.build(:user)
        user.enable_otp
        user.disable_otp
        user.require_otp = true
        user.entered_otp_code = 'invalid'
        expect(user.valid?).to eq(true)
      end

      it 'it has no effect when require_otp is false' do
        user = FactoryBot.build(:user)
        user.enable_otp
        user.require_otp = false
        user.entered_otp_code = 'invalid'
        expect(user.valid?).to eq(true)
      end

      it 'is invalid with an incorrect otp' do
        user = FactoryBot.build(:user)
        user.enable_otp
        user.require_otp = true
        user.entered_otp_code = 'invalid'
        expect(user.valid?).to eq(false)
      end

      it 'is invalid with a nil otp' do
        user = FactoryBot.build(:user)
        user.enable_otp
        user.require_otp = true
        user.entered_otp_code = nil
        expect(user.valid?).to eq(false)
      end

      it 'adds an error for an invalid otp' do
        msg = 'Invalid one time password'
        user = FactoryBot.build(:user)
        user.enable_otp
        user.require_otp = true
        user.entered_otp_code = 'invalid'
        user.valid?
        expect(user.errors[:otp_code]).to include(msg)
      end

      it 'increments the otp_counter if a correct otp_code is used' do
        user = FactoryBot.build(:user)
        user.enable_otp
        user.require_otp = true
        user.entered_otp_code = user.otp_code
        counter = user.otp_counter
        user.valid?
        expect(user.otp_counter).to eq(counter + 1)
      end
    end

    context 'with otp disabled' do
      it 'is valid with any otp' do
        user = FactoryBot.build(:user)
        user.disable_otp
        user.entered_otp_code = 'invalid'
        expect(user.valid?).to eq(true)
      end
    end
  end

  describe '#otp_enabled' do
    it 'defaults to false' do
      user = User.new
      expect(user.otp_enabled).to eq(false)
    end

    it 'can be enabled on initialization' do
      user = User.new(otp_enabled: true)
      expect(user.otp_enabled).to eq(true)
    end

    it 'can be enabled after initialization' do
      user = User.new
      user.otp_enabled = true
      expect(user.otp_enabled).to eq(true)
    end
  end

  describe '#otp_enabled?' do
    it 'requires an otp_secret_key to be enabled' do
      attrs = { otp_enabled: true,
                otp_secret_key: nil,
                otp_counter: 1 }
      user = User.new(attrs)
      expect(user.otp_enabled?).to eq(false)
    end

    it 'requires an otp_counter to be enabled' do
      attrs = { otp_enabled: true,
                otp_secret_key: '123',
                otp_counter: nil }
      user = User.new(attrs)
      expect(user.otp_enabled?).to eq(false)
    end

    it 'requires an otp_enabled to be true to be enabled' do
      attrs = { otp_enabled: false,
                otp_secret_key: '123',
                otp_counter: 1 }
      user = User.new(attrs)
      expect(user.otp_enabled?).to eq(false)
    end

    it 'requires otp_enabled, otp_secret_key and otp_counter to be enabled' do
      attrs = { otp_enabled: true,
                otp_secret_key: '123',
                otp_counter: 1 }
      user = User.new(attrs)
      expect(user.otp_enabled?).to eq(true)
    end
  end

  describe '#enable_otp' do
    it 'resets the otp_counter' do
      user = User.new(otp_counter: 200)
      user.enable_otp
      expect(user.otp_counter).to eq(1)
    end

    it 'regenerates the otp_secret_key' do
      user = User.new(otp_secret_key: '123')
      user.enable_otp
      expect(user.otp_secret_key.length).to eq(32)
    end

    it 'sets otp_enabled to true' do
      user = User.new
      user.enable_otp
      expect(user.otp_enabled).to eq(true)
    end

    it 'returns true' do
      user = User.new
      expect(user.enable_otp).to eq(true)
    end
  end

  describe '#disable_otp' do
    it 'sets otp_enabled to false' do
      user = User.new(otp_enabled: true)
      user.disable_otp
      expect(user.otp_enabled?).to eq(false)
    end

    it 'sets require_otp to false' do
      user = User.new(otp_enabled: true)
      user.require_otp = true
      user.disable_otp
      expect(user.require_otp?).to eq(false)
    end

    it 'returns true' do
      user = User.new
      expect(user.disable_otp).to eq(true)
    end
  end

  describe '#require_otp?' do
    it 'is false by default' do
      user = User.new
      expect(user.require_otp?).to eq(false)
    end

    it 'returns the assigned boolean' do
      user = User.new(require_otp: true)
      expect(user.require_otp?).to eq(true)
    end
  end

  describe '#require_otp=' do
    it 'assigns true for a truthy value' do
      user = User.new
      user.require_otp = 'yes'
      expect(user.require_otp?).to eq(true)
    end

    it 'assigns false for a falsy value' do
      user = User.new
      user.require_otp = nil
      expect(user.require_otp?).to eq(false)
    end
  end

  describe '#otp_counter' do
    it 'defaults to 1' do
      user = User.new
      expect(user.otp_counter).to eq(1)
    end

    it 'can be set on initialization' do
      user = User.new(otp_counter: 200)
      expect(user.otp_counter).to eq(200)
    end

    it 'can be set after initialization' do
      user = User.new
      user.otp_counter = 200
      expect(user.otp_counter).to eq(200)
    end
  end

  describe '#otp_secret_key' do
    it 'can be set on initialization' do
      key = User.otp_random_secret
      user = User.new(otp_secret_key: key)
      expect(user.otp_secret_key).to eq(key)
    end

    it 'can be set after initialization' do
      key = User.otp_random_secret
      user = User.new
      user.otp_secret_key = key
      expect(user.otp_secret_key).to eq(key)
    end
  end

  describe '#entered_otp_code' do
    it 'gets the virtual attribute for use in validation' do
      user = User.new(entered_otp_code: '123456')
      expect(user.entered_otp_code).to eq('123456')
    end
  end

  describe '#entered_otp_code=' do
    it 'sets the virtual attribute for use in validation' do
      user = User.new
      user.entered_otp_code = '123456'
      expect(user.entered_otp_code).to eq('123456')
    end
  end

  describe '#banned?' do
    it 'is banned if the user has ban_text' do
      user = FactoryBot.build(:user, ban_text: 'banned')
      expect(user).to be_banned
    end

    it 'is not banned if the user has no ban_text' do
      user = FactoryBot.build(:user, ban_text: '')
      expect(user).to_not be_banned
    end
  end

  describe '#close_and_anonymise' do
    let(:user) { FactoryBot.create(:user) }

    it 'delegates to close!, anonymise! and erase! methods' do
      expect(user).to receive(:close!)
      expect(user).to receive(:anonymise!)
      expect(user).to receive(:erase!)
      user.close_and_anonymise
    end
  end

  describe '#close' do
    subject { user.close }

    let(:user) { FactoryBot.build(:user) }

    context 'the update is successful' do
      before do
        expect(user).to receive(:close!).and_call_original
        subject
      end

      it { is_expected.to eq(true) }

      it 'closes the account' do
        expect(user).to be_closed
      end
    end

    context 'the update is unsuccessful' do
      before do
        expect(user).to receive(:close!).and_raise(ActiveRecord::RecordInvalid)
        subject
      end

      it { is_expected.to eq(false) }

      it 'does not close the account' do
        expect(user).not_to be_closed
      end
    end
  end

  describe '#close!' do
    subject { user.close! }

    let(:user) { FactoryBot.build(:user) }

    context 'the update is successful' do
      before { subject }

      it 'closes the account' do
        expect(user).to be_closed
      end

      it 'sets closed_at' do
        expect(user.closed_at).to be_present
      end

      it 'disables email alerts' do
        expect(user.receive_email_alerts).to eq(false)
      end
    end

    context 'the update is unsuccessful' do
      before do
        expect(user).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'raises an ActiveRecord::RecordInvalid error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#closed?' do
    let(:user) { FactoryBot.build(:user) }

    it 'should be closed if closed_at present' do
      user.closed_at = Time.zone.now
      expect(user).to be_closed
    end

    it 'should not be closed if closed_at not present' do
      user.closed_at = nil
      expect(user).to_not be_closed
    end
  end

  describe '#erase' do
    subject { user.erase }

    let(:user) { FactoryBot.build(:user) }

    context 'the update is successful' do
      before do
        user.close!
        expect(user).to receive(:erase!).and_call_original
        subject
      end

      it { is_expected.to eq(true) }

      it 'erases the account' do
        expect(user.name).to match(/Name Removed/)
      end
    end

    context 'the update is unsuccessful' do
      before do
        expect(user).to receive(:erase!).and_raise(ActiveRecord::RecordInvalid)
        subject
      end

      it { is_expected.to eq(false) }

      it 'does not erase the account' do
        expect(user.name).not_to match(/Name Removed/)
      end
    end
  end

  describe '#erase!' do
    subject { user.erase! }

    context 'the user account is not closed' do
      let(:user) { FactoryBot.build(:user, about_me: 'Hi') }

      it 'raises an ActiveRecord::RecordInvalid' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'the update is successful' do
      let(:user) { FactoryBot.build(:user, :closed, about_me: 'Hi') }

      let!(:outgoing_message) do
        FactoryBot.create(:initial_request, user: user)
      end

      before do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(1)
        FactoryBot.create(:user_sign_in, user: user)
        FactoryBot.create(:user_email_history, user: user)
        FactoryBot.create(:profile_photo, user: user)

        allow(Digest::SHA1).to receive(:hexdigest).and_return('a1b2c3d4')
        allow(MySociety::Util).
          to receive(:generate_token).and_return('r@nd0m-pa$$w0rd')

        subject

        user.reload
        outgoing_message.reload
      end

      it 'erases the name' do
        # #name currently appends "(Account suspended)". Here we specifically
        # only care about the data we hold.
        expect(user.read_attribute(:name)).to eq('[Name Removed]')
      end

      it 'erases the url_name' do
        expect(user.url_name).to eq('a1b2c3d4')
      end

      it 'erases the email' do
        expect(user.email).to eq('a1b2c3d4@invalid')
      end

      it 'erases the password' do
        expect(user.password).to eq('r@nd0m-pa$$w0rd')
      end

      it 'erases the about_me' do
        expect(user.about_me).to be_empty
      end

      it 'erases outgoing_message the from_name' do
        expect(outgoing_message.from_name).to eq('[Name Removed]')
      end

      it 'destroys any old slugs' do
        # update in the method will create a new slug as the name is changed.
        expect(user.slugs.pluck(:slug)).to eq(['a1b2c3d4'])
      end

      it 'destroys any sign_ins' do
        expect(user.sign_ins).to be_empty
      end

      it 'destroys any email_histories' do
        expect(user.email_histories).to be_empty
      end

      it 'destroys any profile photo' do
        expect(user.profile_photo).to be_nil
      end
    end

    context 'the update is unsuccessful' do
      let(:user) { FactoryBot.build(:user, :closed, about_me: 'Hi') }

      before do
        expect(user).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'raises an ActiveRecord::RecordInvalid error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#anonymise!' do
    subject { user.anonymise! }

    let(:user) { FactoryBot.build(:user, name: 'Bob Smith') }

    context 'when the user has info requests' do
      before { FactoryBot.create(:info_request, user: user) }

      it 'creates a censor rule for user name' do
        subject
        censor_rule = user.censor_rules.find { _1.text = user.name }
        expect(censor_rule).to_not be_nil
        expect(censor_rule.replacement).to eq('[Name Removed]')
        expect(censor_rule.last_edit_editor).to eq('User#anonymise!')
        expect(censor_rule.last_edit_comment).to eq('User#anonymise!')
      end
    end

    context 'when the user has info requests which uses an different name' do
      let(:previous_name) { 'Bob' }

      before do
        FactoryBot.create(:info_request, user: user)
        FactoryBot.create(
          :new_information_followup, user: user, from_name: previous_name
        )
      end

      it 'creates a censor rules for previous names' do
        subject
        censor_rule = user.censor_rules.find { _1.text == previous_name }
        expect(censor_rule).to_not be_nil
        expect(censor_rule.replacement).to eq('[Name Removed]')
        expect(censor_rule.last_edit_editor).to eq('User#anonymise!')
        expect(censor_rule.last_edit_comment).to eq('User#anonymise!')
      end
    end

    context 'when the user has annotations' do
      before { FactoryBot.create(:comment, user: user) }

      it 'creates a censor rule for user name' do
        subject
        censor_rule = user.censor_rules.find { _1.text == user.name }
        expect(censor_rule).to_not be_nil
        expect(censor_rule.replacement).to eq('[Name Removed]')
        expect(censor_rule.last_edit_editor).to eq('User#anonymise!')
        expect(censor_rule.last_edit_comment).to eq('User#anonymise!')
      end
    end

    context 'when the user has no info requests or annotations' do
      it 'does not create a censor rule' do
        subject
        expect(user.censor_rules).to be_empty
      end
    end
  end

  describe '.closed' do
    it 'should not return users with closed_at timestamp' do
      active_user = FactoryBot.create(:user)
      user = FactoryBot.create(:user, closed_at: Time.zone.now)
      expect(User.closed).to_not include(active_user)
      expect(User.closed).to include(user)
    end
  end

  describe '.not_closed' do
    it 'should return users with closed_at timestamp' do
      active_user = FactoryBot.create(:user)
      user = FactoryBot.create(:user, closed_at: Time.zone.now)
      expect(User.not_closed).to include(active_user)
      expect(User.not_closed).to_not include(user)
    end
  end

  describe '#active?' do
    let(:user) { FactoryBot.build(:user) }

    it 'should be active if not banned and not closed' do
      allow(user).to receive(:banned?).and_return(false)
      allow(user).to receive(:closed?).and_return(false)
      expect(user).to be_active
    end

    it 'should not be active if banned' do
      allow(user).to receive(:banned?).and_return(true)
      expect(user).to_not be_active
    end

    it 'should not be active if closed' do
      allow(user).to receive(:closed?).and_return(true)
      expect(user).to_not be_active
    end
  end

  describe '#suspended?' do
    let(:user) { FactoryBot.build(:user) }

    it 'should not be suspended if not banned and not closed' do
      allow(user).to receive(:banned?).and_return(false)
      allow(user).to receive(:closed?).and_return(false)
      expect(user).to_not be_suspended
    end

    it 'should be suspended if banned' do
      allow(user).to receive(:banned?).and_return(true)
      expect(user).to be_suspended
    end

    it 'should be suspended if closed' do
      allow(user).to receive(:closed?).and_return(true)
      expect(user).to be_suspended
    end
  end

  describe '#prominence' do
    subject { user.prominence }

    context 'when the user is banned' do
      let(:user) { FactoryBot.build(:user, :banned) }
      it { is_expected.to eq('hidden') }
    end

    context 'when the user is banned and closed' do
      let(:user) { FactoryBot.build(:user, :banned, :closed) }
      it { is_expected.to eq('hidden') }
    end

    context 'when the user is closed' do
      let(:user) { FactoryBot.build(:user, :closed) }
      it { is_expected.to eq('backpage') }
    end

    context 'when the user is unconfirmed' do
      let(:user) { FactoryBot.build(:user, :unconfirmed) }
      it { is_expected.to eq('backpage') }
    end

    context 'in normal circumstances' do
      let(:user) { FactoryBot.build(:user) }
      it { is_expected.to eq('normal') }
    end
  end

  describe '.active' do
    it 'should not return banned users' do
      active_user = FactoryBot.create(:user)
      user = FactoryBot.create(:user, ban_text: 'banned')
      expect(User.active).to include(active_user)
      expect(User.active).to_not include(user)
    end

    it 'should not return closed users' do
      active_user = FactoryBot.create(:user)
      user = FactoryBot.create(:user, closed_at: Time.zone.now)
      expect(User.active).to include(active_user)
      expect(User.active).to_not include(user)
    end
  end

  describe '.banned' do
    it 'should return banned users' do
      active_user = FactoryBot.create(:user)
      user = FactoryBot.create(:user, ban_text: 'banned')
      expect(User.banned).to_not include(active_user)
      expect(User.banned).to include(user)
    end
  end

  describe '.not_banned' do
    it 'should not return banned users' do
      active_user = FactoryBot.create(:user)
      user = FactoryBot.create(:user, ban_text: 'banned')
      expect(User.not_banned).to include(active_user)
      expect(User.not_banned).not_to include(user)
    end
  end

  describe '#confirm' do
    it 'confirms an unconfirmed user' do
       user = FactoryBot.build(:user, email_confirmed: false)
       user.confirm
       expect(user.email_confirmed).to be(true)
    end

    it 'no-ops a confirmed user' do
      user = FactoryBot.build(:user, email_confirmed: true)
      user.confirm
      expect(user.email_confirmed).to be(true)
    end

    it 'does not save by default' do
      user = FactoryBot.build(:user, email_confirmed: false)
      user.confirm
      expect(user).to be_new_record
    end

    it 'saves the record if passed an argument' do
      user = FactoryBot.build(:user, email_confirmed: false)
      user.confirm(true)
      expect(user).to be_persisted
    end
  end

  describe '#confirm!' do
    it 'confirms an unconfirmed user' do
       user = FactoryBot.build(:user, email_confirmed: false)
       user.confirm!
       expect(user.reload.email_confirmed).to be(true)
    end

    it 'no-ops a confirmed user' do
      user = FactoryBot.build(:user, email_confirmed: true)
      user.confirm!
      expect(user.reload.email_confirmed).to be(true)
    end

    it 'saves the record' do
      user = FactoryBot.build(:user, email_confirmed: false)
      user.confirm!
      expect(user).to be_persisted
    end

    it 'it raises an error on save if the record is invalid' do
      user = FactoryBot.build(:user, email: nil, email_confirmed: false)
      expect { user.confirm! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '.find_user_by_email' do
    it 'finds a user by email case-insensitively' do
      user = FactoryBot.create(:user)
      expect(User.find_user_by_email(user.email.upcase)).to eq(user)
    end

    it 'returns nil when passed nil' do
      expect(User.find_user_by_email(nil)).to eq(nil)
    end

    it 'returns nil when passed an empty string' do
      expect(User.find_user_by_email('')).to eq(nil)
    end

    it 'returns nil when passed a whitespace string' do
      expect(User.find_user_by_email('  ')).to eq(nil)
    end

    it 'matches a padded email' do
      user = FactoryBot.create(:user)
      expect(User.find_user_by_email(" #{user.email} ")).to eq(user)
    end
  end

  describe '#about_me_already_exists?' do
    it 'is true if the about_me text already exists for another user' do
      FactoryBot.create(:user, about_me: '123')
      user = FactoryBot.build(:user, about_me: '123')
      expect(user.about_me_already_exists?).to eq(true)
    end

    it 'is false if the about_me text is unique to the user' do
      User.update_all(about_me: '')
      user = FactoryBot.build(:user, about_me: '123')
      expect(user.about_me_already_exists?).to eq(false)
    end

    it 'is false if the about text is blank' do
      FactoryBot.create(:user, about_me: '')
      user = FactoryBot.build(:user, about_me: '')
      expect(user.about_me_already_exists?).to eq(false)
    end

    it 'does not include the current user in the results' do
      User.update_all(about_me: '')
      user = FactoryBot.create(:user, about_me: '123')
      expect(user.about_me_already_exists?).to eq(false)
    end
  end

  describe '#indexed_by_search?' do
    it 'is false if the user is unconfirmed' do
      user = User.new(email_confirmed: false, ban_text: '')
      expect(user.indexed_by_search?).to eq(false)
    end

    it 'is false if the user is banned' do
      user = User.new(email_confirmed: true, ban_text: 'banned')
      expect(user.indexed_by_search?).to eq(false)
    end

    it 'is false if the user has no requests' do
      user = User.new(email_confirmed: true, ban_text: '')
      expect(user.indexed_by_search?).to eq(false)
    end

    it 'is true if the user is active and has requests' do
      user = FactoryBot.create(:info_request).user
      expect(user.indexed_by_search?).to eq(true)
    end
  end

  describe '#can_admin_roles' do
    it 'returns an array including the admin and roles for an admin user' do
      admin_user = FactoryBot.create(:admin_user)
      expect(admin_user.can_admin_roles).to eq([:admin])
    end

    it 'returns an empty array for a pro user' do
      user = FactoryBot.create(:user)
      expect(user.can_admin_roles).to eq([])
    end

    it 'returns an empty array for a user with no roles' do
      pro_user = FactoryBot.create(:pro_user)
      expect(pro_user.can_admin_roles).to eq([])
    end
  end

  describe '#can_admin_role?' do
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:pro_user) { FactoryBot.create(:pro_user) }

    it 'returns true for an admin user and the admin role' do
      expect(admin_user.can_admin_role?(:admin))
        .to be true
    end

    it 'return false for an admin user and the pro role' do
      expect(admin_user.can_admin_role?(:pro))
        .to be false
    end

    it 'returns false for a pro user and the admin role' do
      expect(pro_user.can_admin_role?(:admin))
        .to be false
    end

    it 'returns false for a pro user and the pro role' do
      expect(pro_user.can_admin_role?(:pro))
        .to be false
    end
  end

  describe '#admin?' do
    subject { user.admin? }

    context 'normal user' do
      let(:user) { FactoryBot.build(:user) }
      it { is_expected.to eq(false) }
    end

    context 'admin' do
      let(:user) { FactoryBot.create(:user, :admin) }
      it { is_expected.to eq(true) }
    end

    context 'pro admin' do
      let(:user) { FactoryBot.create(:user, :pro_admin) }
      it { is_expected.to eq(true) }
    end
  end

  describe 'pro scope' do
    it "only includes pro user" do
      pro_user = FactoryBot.create(:pro_user)
      user = FactoryBot.create(:user)
      expect(User.pro.include?(pro_user)).to be true
      expect(User.pro.include?(user)).to be false
    end
  end

  describe '.info_request_events' do
    let(:user) { FactoryBot.create(:user) }
    let(:info_request) { FactoryBot.create(:info_request, user: user) }
    let!(:response_event) do
      FactoryBot.create(:response_event, info_request: info_request)
    end
    let!(:comment_event) do
      FactoryBot.create(:comment_event, info_request: info_request)
    end
    let!(:resent_event) do
      FactoryBot.create(:resent_event, info_request: info_request)
    end

    it "returns events in descending created_at order" do
      expect(user.info_request_events.first).to eq resent_event
      expect(user.info_request_events.second).to eq comment_event
      expect(user.info_request_events.third).to eq response_event
    end

    it "returns all of the user's events" do
      # NOTE: there is a fourth "sent" event created automatically
      expect(user.info_request_events.count).to eq 4
    end
  end

  describe 'notifications' do
    it 'deletes associated notifications when destroyed' do
      notification = FactoryBot.create(:notification)
      user = notification.user.reload
      expect(Notification.where(id: notification.id)).to exist
      user.destroy
      expect(Notification.where(id: notification.id)).not_to exist
    end
  end

  describe '#owns_every_request?' do
    subject { user.owns_every_request? }

    context 'when the user has no roles' do
      let(:user) { FactoryBot.create(:user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is a pro' do
      let(:user) { FactoryBot.create(:pro_user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is an admin' do
      let(:user) { FactoryBot.create(:admin_user) }
      it { is_expected.to eq(true) }
    end

    context 'when the user is a pro_admin' do
      let(:user) { FactoryBot.create(:user, :pro_admin) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#view_hidden?' do
    subject { user.view_hidden? }

    context 'when the user has no roles' do
      let(:user) { FactoryBot.create(:user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is a pro' do
      let(:user) { FactoryBot.create(:pro_user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is an admin' do
      let(:user) { FactoryBot.create(:admin_user) }
      it { is_expected.to eq(true) }
    end

    context 'when the user is a pro_admin' do
      let(:user) { FactoryBot.create(:user, :pro_admin) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#view_embargoed?' do
    subject { user.view_embargoed? }

    context 'when the user has no roles' do
      let(:user) { FactoryBot.create(:user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is an admin' do
      let(:user) { FactoryBot.create(:admin_user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is an admin', feature: :alaveteli_pro do
      let(:user) { FactoryBot.create(:admin_user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is a pro_admin', feature: :alaveteli_pro do
      let(:user) { FactoryBot.create(:pro_admin_user) }
      it { is_expected.to eq(true) }
    end
  end

  describe '#view_hidden_and_embargoed?' do
    subject { user.view_hidden_and_embargoed? }

    context 'when the user has no roles' do
      let(:user) { FactoryBot.create(:user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is an admin' do
      let(:user) { FactoryBot.create(:admin_user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is an admin', feature: :alaveteli_pro do
      let(:user) { FactoryBot.create(:admin_user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is only a pro_admin', feature: :alaveteli_pro do
      let(:user) { FactoryBot.create(:user, :pro_admin) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is a pro_admin', feature: :alaveteli_pro do
      let(:user) { FactoryBot.create(:pro_admin_user) }
      it { is_expected.to eq(true) }
    end
  end

  describe '#next_daily_summary_time' do
    let(:user) do
      FactoryBot.create(:user, daily_summary_hour: 7,
                               daily_summary_minute: 56)
    end

    context "when the time is in the future" do
      let(:expected_time) { Time.zone.now.change(hour: 7, min: 56) }

      it "returns today's date with the daily summary time set" do
        travel_to(expected_time - 1.minute) do
          expect(user.next_daily_summary_time).
            to be_within(1.second).of(expected_time)
        end
      end
    end

    context "when the time is in the past" do
      let(:expected_time) { Time.zone.now.change(hour: 7, min: 56) + 1.day }

      it "returns tomorrow's date with the daily summary time set" do
        travel_to(Time.zone.now.change(hour: 7, min: 57)) do
          expect(user.next_daily_summary_time).
            to be_within(1.second).of(expected_time)
        end
      end
    end
  end

  describe '#notification_frequency' do
    context 'when the user has :notifications' do
      let(:user) { FactoryBot.create(:user) }

      before do
        AlaveteliFeatures.backend[:notifications].enable_actor user
      end

      it 'returns Notification::DAILY' do
        expect(user.notification_frequency).to eq(Notification::DAILY)
      end
    end

    context 'when the user doesnt have :notifications' do
      let(:user) { FactoryBot.create(:user) }

      it 'returns Notification::INSTANTLY' do
        expect(user.notification_frequency).to eq(Notification::INSTANTLY)
      end
    end
  end

  describe "#notify" do
    let(:info_request_event) { FactoryBot.create(:response_event) }
    let(:user) { info_request_event.info_request.user }

    it "creates a notification" do
      expect { user.notify(info_request_event) }.
        to change { Notification.count }.by 1
    end

    it "calls notification_frequency" do
      expect(user).to receive(:notification_frequency)
      user.notify(info_request_event)
    end
  end

  describe '#features' do
    let(:user) { FactoryBot.build(:user) }

    it 'delegates to AlaveteliFeatures' do
      features = double(:features)
      expect(AlaveteliFeatures).to receive(:features).and_return(features)
      expect(features).to receive(:with_actor).with(user)
      user.features
    end
  end

  describe '#features=' do
    let(:user) { FactoryBot.build(:user) }

    it 'enables features' do
      features = double(:features)
      allow(user).to receive(:features).and_return(features)
      expect(features).to receive(:assign_features).with([:new_feature])
      user.features = [:new_feature]
    end
  end

  describe "#flipper_id" do
    let(:user) { FactoryBot.create(:user) }

    it "returns the user's id, prefixed with the class name" do
      expect(user.flipper_id).to eq("User;#{user.id}")
    end
  end

  describe 'role callbacks' do
    let(:user) { FactoryBot.build(:user) }

    context 'adding unknown role' do
      it 'enables user role features' do
        features = double(:features)
        allow(user).to receive(:features).and_return(features)
        expect(features).to receive(:assign_role_features)
        user.add_role(:unknown)
      end
    end

    context 'adding pro role' do
      it 'enables user role features' do
        features = double(:features)
        allow(user).to receive(:features).and_return(features)
        expect(features).to receive(:assign_role_features)
        user.add_role(:pro)
      end
    end

    context 'with pro pricing enabled', feature: :pro_pricing do
      it 'creates pro account when pro role added' do
        expect { user.add_role :pro }.to change(user, :pro_account).
          from(nil).to(ProAccount)
      end
    end

    context 'without pro pricing enabled' do
      it 'does not create pro account when pro role is added' do
        expect { user.add_role :pro }.to_not change(user, :pro_account).
          from(nil)
      end
    end
  end

  describe 'update callbacks' do
    let(:user) { FactoryBot.create(:pro_user, email: 'old@example.com') }

    context 'changing email address of a pro user' do
      let(:pro_account) { double(:pro_account) }

      before do
        allow(user).to receive(:pro_account).and_return(pro_account)
      end

      it 'calls update_stripe_customer on Pro Account' do
        expect(pro_account).to receive(:update_stripe_customer)
        user.run_callbacks :update
      end
    end
  end

  describe '#show_profile_photo?' do
    subject { user.show_profile_photo? }

    context 'with a profile_photo' do
      let(:user) { FactoryBot.create(:user) }

      before do
        user.create_profile_photo!(data: load_file_fixture('parrot.png'))
      end

      it { is_expected.to eq(true) }
    end

    context 'with a profile photo and banned' do
      let(:user) { FactoryBot.create(:user, :banned) }

      before do
        user.create_profile_photo!(data: load_file_fixture('parrot.png'))
      end

      it { is_expected.to eq(false) }
    end

    context 'with profile_photo but profile is limited' do
      let(:user) { FactoryBot.create(:user, :limited) }

      before do
        user.create_profile_photo!(data: load_file_fixture('parrot.png'))
      end

      it { is_expected.to eq(false) }
    end

    context 'without a profile_photo' do
      let(:user) { FactoryBot.build(:user) }
      it { is_expected.to eq(false) }
    end
  end

  describe 'show_about_me?' do
    subject { user.show_about_me? }

    context 'with about_me text' do
      let(:user) { FactoryBot.create(:user, about_me: 'Hello') }
      it { is_expected.to eq(true) }
    end

    context 'with about_me text and banned' do
      let(:user) { FactoryBot.create(:user, :banned, about_me: 'Hello') }
      it { is_expected.to eq(false) }
    end

    context 'with about_me text but profile is limited' do
      let(:user) { FactoryBot.create(:user, :limited, about_me: 'Hello') }
      it { is_expected.to eq(false) }
    end

    context 'without about_me text' do
      let(:user) { FactoryBot.build(:user, about_me: nil) }
      it { is_expected.to eq(false) }
    end
  end

  describe 'get_about_me_for_html_display' do
    subject { user.get_about_me_for_html_display }

    let(:user) { FactoryBot.build(:user) }

    it "adds anchors with rel nofollow links to plain text links" do
      user.about_me = link = "http://example.com"
      is_expected.to include(%Q[<a href="#{link}" rel="nofollow">#{link}</a>])
    end
  end

  describe '#no_limit?' do
    subject { user.no_limit? }

    let(:user) { FactoryBot.build(:user) }
    it { is_expected.to eq(false) }

    context 'when user has no limit set' do
      let(:user) { FactoryBot.build(:user, no_limit: true) }
      it { is_expected.to eq(true) }
    end

    context 'when user is an admin' do
      let(:user) { FactoryBot.create(:admin_user) }
      it { is_expected.to eq(true) }
    end

    context 'when user is an pro admin' do
      let(:user) { FactoryBot.create(:pro_admin_user) }
      it { is_expected.to eq(true) }
    end
  end

  describe '#exceeded_request_limits?' do
    subject { user.exceeded_request_limits? }

    context 'in ordinary circumstances' do
      let(:user) { FactoryBot.build(:user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is inactive' do
      let(:user) { FactoryBot.build(:user) }
      before { allow(user).to receive(:active?).and_return(false) }
      it { is_expected.to eq(true) }
    end

    context 'when the user has reached their daily limit' do
      let(:user) { FactoryBot.build(:user) }

      before do
        allow(user).
          to receive(:exceeded_limit?).with(:info_requests).and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when the user has not reached their rate limit' do
      let(:user) { FactoryBot.build(:user) }

      before do
        expect(InfoRequest).
          to receive(:exceeded_creation_rate?).
          with(user.info_requests).
          and_return(false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when the user has reached their rate limit' do
      let(:user) { FactoryBot.build(:user) }

      before do
        expect(InfoRequest).
          to receive(:exceeded_creation_rate?).
          with(user.info_requests).
          and_return(true)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#exceeded_comment_limits?' do
    subject { user.exceeded_comment_limits? }

    context 'in ordinary circumstances' do
      let(:user) { FactoryBot.build(:user) }
      it { is_expected.to eq(false) }
    end

    context 'when the user is inactive' do
      let(:user) { FactoryBot.build(:user) }
      before { allow(user).to receive(:active?).and_return(false) }
      it { is_expected.to eq(true) }
    end

    context 'when the user is an admin' do
      let(:user) { FactoryBot.create(:user, :admin) }

      # Irrespective of how many comments they've made
      before do
        allow(user).
          to receive(:exceeded_limit?).with(:comments).and_return(true)

        allow(Comment).
          to receive(:exceeded_creation_rate?).
          with(user.comments).
          and_return(true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when the user is a pro_admin' do
      let(:user) { FactoryBot.create(:user, :pro_admin) }

      # Irrespective of how many comments they've made
      before do
        allow(user).
          to receive(:exceeded_limit?).with(:comments).and_return(true)

        allow(Comment).
          to receive(:exceeded_creation_rate?).
          with(user.comments).
          and_return(true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when the user has no limit set' do
      let(:user) { FactoryBot.create(:user, no_limit: true) }

      # Irrespective of how many comments they've made
      before do
        allow(user).
          to receive(:exceeded_limit?).with(:comments).and_return(true)

        allow(Comment).
          to receive(:exceeded_creation_rate?).
          with(user.comments).
          and_return(true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when the user has reached their daily limit' do
      let(:user) { FactoryBot.build(:user) }

      before do
        allow(user).
          to receive(:exceeded_limit?).with(:comments).and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when the user has not reached their rate limit' do
      let(:user) { FactoryBot.build(:user) }

      before do
        allow(Comment).
          to receive(:exceeded_creation_rate?).
          with(user.comments).
          and_return(false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when the user has reached their rate limit' do
      let(:user) { FactoryBot.build(:user) }

      before do
        allow(Comment).
          to receive(:exceeded_creation_rate?).
          with(user.comments).
          and_return(true)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#exceeded_limit?' do
    subject { user.exceeded_limit?(content) }

    let(:user) { FactoryBot.create(:user) }
    let(:content) { :stub_class }

    context 'no limit is set' do
      before do
        allow(user).to receive(:content_limit).with(content).and_return(nil)
      end

      it { is_expected.to eq(false) }
    end

    context 'the user has no limit' do
      before do
        user.no_limit = true
        allow(user).to receive(:content_limit).with(content).and_return(0)
      end

      it { is_expected.to eq(false) }
    end

    context 'the user can make batch requests' do
      before do
        user.can_make_batch_requests = true
        allow(user).to receive(:content_limit).with(content).and_return(0)
      end

      it { is_expected.to eq(false) }
    end

    context 'limiting info_requests' do
      let(:content) { :info_requests }
      before { FactoryBot.create(:info_request, user: user) }

      it 'returns false if the user has not submitted more than the limit' do
        allow(user).to receive(:content_limit).with(content).and_return(2)
        is_expected.to eq(false)
      end

      it 'returns true if the user has submitted more than the limit' do
        allow(user).to receive(:content_limit).with(content).and_return(0)
        is_expected.to eq(true)
      end
    end

    context 'limiting comments' do
      let(:content) { :comments }
      before { FactoryBot.create(:comment, user: user) }

      it 'returns false if the user has not submitted more than the limit' do
        allow(user).to receive(:content_limit).with(content).and_return(2)
        is_expected.to eq(false)
      end

      it 'returns true if the user has submitted more than the limit' do
        allow(user).to receive(:content_limit).with(content).and_return(0)
        is_expected.to eq(true)
      end
    end

    context 'limiting user messages' do
      let(:content) { :user_messages }
      before { FactoryBot.create(:user_message, user: user) }

      it 'returns false if the user has not submitted more than the limit' do
        allow(user).to receive(:content_limit).with(content).and_return(2)
        is_expected.to eq(false)
      end

      it 'returns true if the user has submitted more than the limit' do
        allow(user).to receive(:content_limit).with(content).and_return(0)
        is_expected.to eq(true)
      end
    end
  end

  describe '#info_request_count_changed' do
    let(:user) { FactoryBot.create(:user) }

    it 'mark as needed to be indexed' do
      expect(user).to receive(:xapian_mark_needs_index)
      user.info_request_count_changed
    end
  end

  describe '#record_sign_in' do
    let(:user) { FactoryBot.create(:user) }

    let(:ip) { '192.168.1.1' }
    let(:country) { 'GB' }
    let(:user_agent) { 'Mozilla/5.0' }

    context 'when retaining sign ins is enabled' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(1)
      end

      it 'creates sign_in instance with given arguments' do
        expect {
          user.record_sign_in(ip: ip, country: country, user_agent: user_agent)
        }.to change { user.sign_ins.count }.by(1)

        sign_in = user.sign_ins.first
        expect(sign_in.ip).to eq(ip)
        expect(sign_in.country).to eq(country)
        expect(sign_in.user_agent).to eq(user_agent)
      end

      it 'touches last_sign_in_at' do
        expect { user.record_sign_in(ip: '192.168.1.1') }.
          to change(user, :last_sign_in_at).from(nil)
        expect(user.last_sign_in_at).to be_a(Time)
      end
    end

    context 'when retaining sign ins is disabled' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(0)
      end

      it 'does not create sign_in instance' do
        expect {
          user.record_sign_in(ip: ip, country: country, user_agent: user_agent)
        }.not_to change { user.sign_ins.count }
      end

      it 'touches last_sign_in_at' do
        expect { user.record_sign_in(ip: '192.168.1.1') }.
          to change(user, :last_sign_in_at).from(nil)
        expect(user.last_sign_in_at).to be_a(Time)
      end
    end
  end
end

# -*- encoding : utf-8 -*-
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
#  last_daily_track_email            :datetime         default(Sat, 01 Jan 2000 00:00:00 GMT +00:00)
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  it_behaves_like 'PhaseCounts'
end

describe User, "making up the URL name" do
  before do
    @user = User.new
  end

  it 'should remove spaces, and make lower case' do
    @user.name = 'Some Name'
    expect(@user.url_name).to eq('some_name')
  end

  it 'should not allow a numeric name' do
    @user.name = '1234'
    expect(@user.url_name).to eq('user')
  end
end

describe User, "banning the user" do

  it 'does not change the URL name' do
    user = FactoryGirl.create(:user, :name => 'nasty user 123')
    user.update_attributes(:ban_text => 'You are banned')
    expect(user.url_name).to eq('nasty_user_123')
  end

  it 'does not change the stored name' do
    user = FactoryGirl.create(:user, :name => 'nasty user 123')
    user.update_attributes(:ban_text => 'You are banned')
    expect(user.read_attribute(:name)).to eq('nasty user 123')
  end

  it 'appends a message to the name' do
    user = FactoryGirl.build(:user, :name => 'nasty user', :ban_text => 'banned')
    expect(user.name).to eq('nasty user (Account suspended)')
  end

end

describe User, "showing the name" do
  before do
    @user = User.new
    @user.name = 'Some Name '
  end

  it 'should strip whitespace' do
    expect(@user.name).to eq('Some Name')
  end

  describe  'if user has been banned' do

    before do
      @user.ban_text = "Naughty user"
    end

    it 'should show an "Account suspended" suffix' do
      expect(@user.name).to eq('Some Name (Account suspended)')
    end

  end


end

describe User, " when authenticating" do
  before do
    @empty_user = User.new

    @full_user = User.new
    @full_user.name = "Sensible User"
    @full_user.password = "foolishpassword"
    @full_user.email = "sensible@localhost"
    @full_user.save
  end

  it "should create a hashed password when the password is set" do
    expect(@empty_user.hashed_password).to be_nil
    @empty_user.password = "a test password"
    expect(@empty_user.hashed_password).not_to be_nil
  end

  it "should have errors when given the wrong password" do
    found_user = User.authenticate_from_form({ :email => "sensible@localhost", :password => "iownzyou" })
    expect(found_user.errors.size).to be > 0
  end

  it "should not find the user when given the wrong email" do
    found_user = User.authenticate_from_form( { :email => "soccer@localhost", :password => "foolishpassword" })
    expect(found_user.errors.size).to be > 0
  end

  it "should find the user when given the right email and password" do
    found_user = User.authenticate_from_form( { :email => "sensible@localhost", :password => "foolishpassword" })
    expect(found_user.errors.size).to eq(0)
    expect(found_user).to eq(@full_user)
  end

end

describe User, 'password hashing algorithms' do
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

describe User, 'when saving' do
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
    @user.save
    expect(@user).to be_valid
  end

  it 'should let you make two users with same name' do
    @user.name = 'Mr. Flobble'
    @user.password = 'insecurepassword'
    @user.email = 'flobble@localhost'
    @user.save
    expect(@user).to be_valid

    @user2 = User.new
    @user2.name = 'Mr. Flobble'
    @user2.password = 'insecurepassword'
    @user2.email = 'flobble2@localhost'
    @user2.save
    expect(@user2).to be_valid
  end

  it 'should not let you make two users with same email' do
    @user.name = 'Mr. Flobble'
    @user.password = 'insecurepassword'
    @user.email = 'flobble@localhost'
    @user.save
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
    @user.save
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

  it 'should mark the model for reindexing in xapian if the no_xapian_reindex flag is not set'  do
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


describe User, "when reindexing referencing models" do

  before do
    @request_event = mock_model(InfoRequestEvent, :xapian_mark_needs_index => true)
    @request = mock_model(InfoRequest, :info_request_events => [@request_event])
    @comment_event = mock_model(InfoRequestEvent, :xapian_mark_needs_index => true)
    @comment = mock_model(Comment, :info_request_events => [@comment_event])
    @user = User.new(:comments => [@comment], :info_requests => [@request])
  end

  it 'should reindex events associated with that user\'s comments when URL changes' do
    allow(@user).to receive(:changes).and_return({'url_name' => 1})
    expect(@comment_event).to receive(:xapian_mark_needs_index)
    @user.reindex_referencing_models
  end

  it 'should reindex events associated with that user\'s requests when URL changes' do
    allow(@user).to receive(:changes).and_return({'url_name' => 1})
    expect(@request_event).to receive(:xapian_mark_needs_index)
    @user.reindex_referencing_models
  end

  describe 'when no_xapian_reindex is set' do
    before do
      @user.no_xapian_reindex = true
    end

    it 'should not reindex events associated with that user\'s comments when URL changes' do
      allow(@user).to receive(:changes).and_return({'url_name' => 1})
      expect(@comment_event).not_to receive(:xapian_mark_needs_index)
      @user.reindex_referencing_models
    end

    it 'should not reindex events associated with that user\'s requests when URL changes' do
      allow(@user).to receive(:changes).and_return({'url_name' => 1})
      expect(@request_event).not_to receive(:xapian_mark_needs_index)
      @user.reindex_referencing_models
    end

  end

end

describe User, "when checking abilities" do

  before do
    @user = users(:bob_smith_user)
  end

  it "should not get admin links" do
    expect(@user.admin_page_links?).to be false
  end

  it "should be able to file requests" do
    expect(@user.can_file_requests?).to be true
  end

end

describe User, 'when asked if a user owns every request' do

  before do
    @mock_user = mock_model(User)
  end

  it 'should return false if no user is passed' do
    expect(User.owns_every_request?(nil)).to be false
  end

  it 'should return true if the user has "requires admin" power' do
    allow(@mock_user).to receive(:owns_every_request?).and_return true
    expect(User.owns_every_request?(@mock_user)).to be true
  end

  it 'should return false if the user does not have "requires admin" power' do
    allow(@mock_user).to receive(:owns_every_request?).and_return false
    expect(User.owns_every_request?(@mock_user)).to be false
  end

end

describe User, " when making name and email address" do
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
describe User, "when setting a profile photo" do
  before do
    @user = User.new
    @user.name = "Sensible User"
    @user.email = "sensible@localhost"
    @user.password = "sensiblepassword"
  end

  it "should attach it to the user" do
    data = load_file_fixture("parrot.png")
    profile_photo = ProfilePhoto.new(:data => data)
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

describe User, "when unconfirmed" do

  before do
    @user = users(:unconfirmed_user)
  end

  it "should not be emailed" do
    expect(@user.should_be_emailed?).to be false
  end
end

describe User, "when emails have bounced" do

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

describe User, "when calculating if a user has exceeded the request limit" do

  before do
    @info_request = FactoryGirl.create(:info_request)
    @user = @info_request.user
  end

  it 'should return false if no request limit is set' do
    allow(AlaveteliConfiguration).to receive(:max_requests_per_user_per_day).and_return nil
    expect(@user.exceeded_limit?).to be false
  end

  it 'should return false if the user has not submitted more than the limit' do
    allow(AlaveteliConfiguration).to receive(:max_requests_per_user_per_day).and_return(2)
    expect(@user.exceeded_limit?).to be false
  end

  it 'should return true if the user has submitted more than the limit' do
    allow(AlaveteliConfiguration).to receive(:max_requests_per_user_per_day).and_return(0)
    expect(@user.exceeded_limit?).to be true
  end

  it 'should return false if the user is allowed to make batch requests' do
    @user.can_make_batch_requests = true
    allow(AlaveteliConfiguration).to receive(:max_requests_per_user_per_day).and_return(0)
    expect(@user.exceeded_limit?).to be false
  end


end

describe User do

  describe '.stay_logged_in_on_redirect?' do

    it 'is false if the user is nil' do
      expect(User.stay_logged_in_on_redirect?(nil)).to eq(false)
    end

    it 'is true if the user is an admin' do
      admin = double(:is_admin? => true)
      expect(User.stay_logged_in_on_redirect?(admin)).to eq(true)
    end

    it 'is false if the user is not an admin' do
      user = double(:is_admin? => false)
      expect(User.stay_logged_in_on_redirect?(user)).to eq(false)
    end

  end

  describe '.all_time_requesters' do

    it 'gets most frequent requesters' do
      User.destroy_all

      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.create(:user)
      user3 = FactoryGirl.create(:user)

      time_travel_to(6.months.ago) do
        5.times { FactoryGirl.create(:info_request, user: user1) }
        2.times { FactoryGirl.create(:info_request, user: user2) }
        FactoryGirl.create(:info_request, user: user3)
      end

      expect(User.all_time_requesters).
        to eq({ user1 => 5,
                user2 => 2,
                user3 => 1 })
    end

  end

  describe '.last_28_day_requesters' do
    it 'gets recent frequent requesters' do
      user_with_3_requests = FactoryGirl.create(:user)
      3.times { FactoryGirl.create(:info_request, user: user_with_3_requests) }
      user_with_2_requests = FactoryGirl.create(:user)
      2.times { FactoryGirl.create(:info_request, user: user_with_2_requests) }
      user_with_1_request = FactoryGirl.create(:user)
      FactoryGirl.create(:info_request, user: user_with_1_request)
      user_with_an_old_request = FactoryGirl.create(:user)
      FactoryGirl.create(:info_request, user: user_with_an_old_request, created_at: 2.months.ago)

      expect(User.last_28_day_requesters).to eql(
        {
          user_with_3_requests => 3,
          user_with_2_requests => 2,
          user_with_1_request => 1
        }
      )
    end
  end

  describe '.all_time_commenters' do
    it 'gets most frequent commenters' do
      # FIXME: This uses fixtures. Change it to use factories when we can.
      expect(User.all_time_commenters).to eql(
        {
          users(:bob_smith_user) => 1,
          users(:silly_name_user) => 1
        }
      )
    end
  end

  describe '.last_28_day_commenters' do
    it 'gets recent frequent commenters' do
      user_with_3_comments = FactoryGirl.create(:user)
      3.times { FactoryGirl.create(:comment, user: user_with_3_comments) }
      user_with_2_comments = FactoryGirl.create(:user)
      2.times { FactoryGirl.create(:comment, user: user_with_2_comments) }
      user_with_1_comment = FactoryGirl.create(:user)
      FactoryGirl.create(:comment, user: user_with_1_comment)
      user_with_an_old_comment = FactoryGirl.create(:user)
      FactoryGirl.create(:comment, user: user_with_an_old_comment, created_at: 2.months.ago)

      expect(User.last_28_day_commenters).to eql(
        {
          user_with_3_comments => 3,
          user_with_2_comments => 2,
          user_with_1_comment => 1
        }
      )
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
          new(user, :transaction_associations => [:comments, :info_requests])
      expect(user.transactions(:comments, :info_requests)).to eq(calculator)
    end

  end

  describe '#destroy' do

    let(:user) { FactoryGirl.create(:user) }

    it 'destroys any associated info_requests' do
      info_request = FactoryGirl.create(:info_request)
      info_request.user.reload.destroy
      expect(InfoRequest.where(:id => info_request.id)).to be_empty
    end

    it 'destroys any associated user_info_request_sent_alerts' do
      info_request = FactoryGirl.create(:info_request)
      alert = user.user_info_request_sent_alerts.build(:info_request => info_request,
                                                       :alert_type => 'overdue_1')
      user.destroy
      expect(UserInfoRequestSentAlert.where(:id => alert.id)).to be_empty
    end

    it 'destroys any associated post_redirects' do
      post_redirect = PostRedirect.create(:uri => '/',
                                          :user_id => user.id)
      user.destroy
      expect(PostRedirect.where(:id => post_redirect.id)).to be_empty
    end

    it 'destroys any associated track_things' do
      track_thing = FactoryGirl.create(:search_track)
      track_thing.tracking_user.destroy
      expect(TrackThing.where(:id => track_thing.id)).to be_empty
    end

    it 'destroys any associated comments' do
      comment = FactoryGirl.create(:comment)
      comment.user.destroy
      expect(Comment.where(:id => comment.id)).to be_empty
    end

    it 'destroys any associated public_body_change_requests' do
      change_request = FactoryGirl.create(:add_body_request)
      change_request.user.destroy
      expect(PublicBodyChangeRequest.where(:id => change_request.id))
        .to be_empty
    end

    it 'destroys any associated profile_photos' do
      profile_photo = user.create_profile_photo(:data => 'xxx')
      user.destroy
      expect(ProfilePhoto.where(:id => profile_photo.id)).to be_empty
    end

    it 'destroys any associated censor_rules' do
      censor_rule = FactoryGirl.create(:user_censor_rule)
      censor_rule.user.destroy
      expect(CensorRule.where(:id => censor_rule.id)).to be_empty
    end

    it 'destroys any associated info_request_batches' do
      info_request_batch = FactoryGirl.create(:info_request_batch)
      info_request_batch.user.destroy
      expect(InfoRequestBatch.where(:id => info_request_batch.id)).to be_empty
    end

    it 'destroys any associated request_classifications' do
      request_classification = FactoryGirl.create(:request_classification)
      request_classification.user.destroy
      expect(RequestClassification.where(:id => request_classification.id))
        .to be_empty
    end

  end

  describe '#expire_requests' do

    it 'calls expire on all associated requests' do
      user = FactoryGirl.build(:user)
      requests = [double, double]
      expect(user).to receive(:info_requests).and_return(requests)

      requests.each do |request|
        expect(request).to receive(:expire)
      end

      user.expire_requests
    end

  end

  describe '#valid?' do

    context 'with require_otp' do

      it 'has no effect when otp is disabled' do
        user = FactoryGirl.build(:user)
        user.enable_otp
        user.disable_otp
        user.require_otp = true
        user.entered_otp_code = 'invalid'
        expect(user.valid?).to eq(true)
      end

      it 'it has no effect when require_otp is false' do
        user = FactoryGirl.build(:user)
        user.enable_otp
        user.require_otp = false
        user.entered_otp_code = 'invalid'
        expect(user.valid?).to eq(true)
      end

      it 'is invalid with an incorrect otp' do
        user = FactoryGirl.build(:user)
        user.enable_otp
        user.require_otp = true
        user.entered_otp_code = 'invalid'
        expect(user.valid?).to eq(false)
      end

      it 'is invalid with a nil otp' do
        user = FactoryGirl.build(:user)
        user.enable_otp
        user.require_otp = true
        user.entered_otp_code = nil
        expect(user.valid?).to eq(false)
      end

      it 'adds an error for an invalid otp' do
        msg = 'Invalid one time password'
        user = FactoryGirl.build(:user)
        user.enable_otp
        user.require_otp = true
        user.entered_otp_code = 'invalid'
        user.valid?
        expect(user.errors[:otp_code]).to include(msg)
      end

      it 'increments the otp_counter if a correct otp_code is used' do
        user = FactoryGirl.build(:user)
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
        user = FactoryGirl.build(:user)
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
      user = User.new(:otp_enabled => true)
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
      attrs = { :otp_enabled => true,
                :otp_secret_key => nil,
                :otp_counter => 1 }
      user = User.new(attrs)
      expect(user.otp_enabled?).to eq(false)
    end

    it 'requires an otp_counter to be enabled' do
      attrs = { :otp_enabled => true,
                :otp_secret_key => '123',
                :otp_counter => nil }
      user = User.new(attrs)
      expect(user.otp_enabled?).to eq(false)
    end

    it 'requires an otp_enabled to be true to be enabled' do
      attrs = { :otp_enabled => false,
                :otp_secret_key => '123',
                :otp_counter => 1 }
      user = User.new(attrs)
      expect(user.otp_enabled?).to eq(false)
    end

    it 'requires otp_enabled, otp_secret_key and otp_counter to be enabled' do
      attrs = { :otp_enabled => true,
                :otp_secret_key => '123',
                :otp_counter => 1 }
      user = User.new(attrs)
      expect(user.otp_enabled?).to eq(true)
    end

  end

  describe '#enable_otp' do

    it 'resets the otp_counter' do
      user = User.new(:otp_counter => 200)
      user.enable_otp
      expect(user.otp_counter).to eq(1)
    end

    it 'regenerates the otp_secret_key' do
      user = User.new(:otp_secret_key => '123')
      user.enable_otp
      expect(user.otp_secret_key.length).to eq(16)
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
      user = User.new(:otp_enabled => true)
      user.disable_otp
      expect(user.otp_enabled?).to eq(false)
    end

    it 'sets require_otp to false' do
      user = User.new(:otp_enabled => true)
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
      user = User.new(:require_otp => true)
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
      user = User.new(:otp_counter => 200)
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
      key = ROTP::Base32.random_base32
      user = User.new(:otp_secret_key => key)
      expect(user.otp_secret_key).to eq(key)
    end

    it 'can be set after initialization' do
      key = ROTP::Base32.random_base32
      user = User.new
      user.otp_secret_key = key
      expect(user.otp_secret_key).to eq(key)
    end

  end

  describe '#entered_otp_code' do

    it 'gets the virtual attribue for use in validation' do
      user = User.new(:entered_otp_code => '123456')
      expect(user.entered_otp_code).to eq('123456')
    end

  end

  describe '#entered_otp_code=' do

    it 'sets the virtual attribue for use in validation' do
      user = User.new
      user.entered_otp_code = '123456'
      expect(user.entered_otp_code).to eq('123456')
    end

  end

  describe '#banned?' do

    it 'is banned if the user has ban_text' do
      user = FactoryGirl.build(:user, :ban_text => 'banned')
      expect(user).to be_banned
    end

    it 'is not banned if the user has no ban_text' do
      user = FactoryGirl.build(:user, :ban_text => '')
      expect(user).to_not be_banned
    end

  end

  describe '.banned' do

    it 'should return banned users' do
      user = FactoryGirl.create(:user, :ban_text => 'banned')
      expect(User.banned).to include(user)
    end

  end

  describe '.not_banned' do

    it 'should not return banned users' do
      user = FactoryGirl.create(:user, :ban_text => 'banned')
      expect(User.not_banned).not_to include(user)
    end

  end

  describe '#confirm' do

    it 'confirms an unconfirmed user' do
       user = FactoryGirl.build(:user, :email_confirmed => false)
       user.confirm
       expect(user.email_confirmed).to be(true)
    end

    it 'no-ops a confirmed user' do
       user = FactoryGirl.build(:user, :email_confirmed => true)
       user.confirm
       expect(user.email_confirmed).to be(true)
    end

    it 'does not save by default' do
      user = FactoryGirl.build(:user, :email_confirmed => false)
      user.confirm
      expect(user).to be_new_record
    end

    it 'saves the record if passed an argument' do
      user = FactoryGirl.build(:user, :email_confirmed => false)
      user.confirm(true)
      expect(user).to be_persisted
    end

  end

  describe '#confirm!' do

    it 'confirms an unconfirmed user' do
       user = FactoryGirl.build(:user, :email_confirmed => false)
       user.confirm!
       expect(user.reload.email_confirmed).to be(true)
    end

    it 'no-ops a confirmed user' do
       user = FactoryGirl.build(:user, :email_confirmed => true)
       user.confirm!
       expect(user.reload.email_confirmed).to be(true)
    end

    it 'saves the record' do
      user = FactoryGirl.build(:user, :email_confirmed => false)
      user.confirm!
      expect(user).to be_persisted
    end

    it 'it raises an error on save if the record is invalid' do
      user = FactoryGirl.build(:user, :email => nil, :email_confirmed => false)
      expect { user.confirm! }.to raise_error(ActiveRecord::RecordInvalid)
    end

  end

  describe '.find_user_by_email' do

    it 'finds a user by email case-insensitively' do
      user = FactoryGirl.create(:user)
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
      user = FactoryGirl.create(:user)
      expect(User.find_user_by_email(" #{user.email} ")).to eq(user)
    end

  end

  describe '#about_me_already_exists?' do

    it 'is true if the about_me text already exists for another user' do
      FactoryGirl.create(:user, :about_me => '123')
      user = FactoryGirl.build(:user, :about_me => '123')
      expect(user.about_me_already_exists?).to eq(true)
    end

    it 'is false if the about_me text is unique to the user' do
      User.update_all(:about_me => '')
      user = FactoryGirl.build(:user, :about_me => '123')
      expect(user.about_me_already_exists?).to eq(false)
    end

  end

  describe '#indexed_by_search?' do

    it 'is false if the user is unconfirmed' do
      user = User.new(:email_confirmed => false, :ban_text => '')
      expect(user.indexed_by_search?).to eq(false)
    end

    it 'is false if the user is banned' do
      user = User.new(:email_confirmed => true, :ban_text => 'banned')
      expect(user.indexed_by_search?).to eq(false)
    end

    it 'is true if the user is confirmed and not banned' do
      user = User.new(:email_confirmed => true, :ban_text => '')
      expect(user.indexed_by_search?).to eq(true)
    end

  end

  describe '#can_admin_roles' do

    it 'returns an array including the admin and roles for an admin user' do
      admin_user = FactoryGirl.create(:admin_user)
      expect(admin_user.can_admin_roles).to eq([:admin])
    end

    it 'returns an empty array for a pro user' do
      user = FactoryGirl.create(:user)
      expect(user.can_admin_roles).to eq([])
    end

    it 'returns an empty array for a user with no roles' do
      pro_user = FactoryGirl.create(:pro_user)
      expect(pro_user.can_admin_roles).to eq([])
    end

  end

  describe '#can_admin_role?' do
    let(:admin_user){ FactoryGirl.create(:admin_user) }
    let(:pro_user){ FactoryGirl.create(:pro_user) }

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

  describe 'pro scope' do
    it "only includes pro user" do
      pro_user = FactoryGirl.create(:pro_user)
      user = FactoryGirl.create(:user)
      expect(User.pro.include?(pro_user)).to be true
      expect(User.pro.include?(user)).to be false
    end
  end

  describe '.view_hidden?' do
    it 'returns false if there is no user' do
      expect(User.view_hidden?(nil)).to be false
    end

    it 'returns false if the user is not a superuser' do
      expect(User.view_hidden?(FactoryGirl.create(:user))).to be false
    end

    it 'returns true if the user is an admin user' do
      expect(User.view_hidden?(FactoryGirl.create(:admin_user))).to be true
    end
  end

  describe '.view_embargoed' do
    it 'returns false if there is no user' do
      expect(User.view_embargoed?(nil)).to be false
    end

    it 'returns false if the user has no roles' do
      expect(User.view_embargoed?(FactoryGirl.create(:user))).to be false
    end

    it 'returns false if the user is an admin user' do
      expect(User.view_embargoed?(FactoryGirl.create(:admin_user))).to be false
    end

    context 'with pro enabled' do

      it 'returns false if the user is an admin user' do
        with_feature_enabled(:alaveteli_pro) do
          expect(User.view_embargoed?(FactoryGirl.create(:admin_user))).to be false
        end
      end

      it 'returns true if the user is a pro_admin user' do
        with_feature_enabled(:alaveteli_pro) do
          expect(User.view_embargoed?(FactoryGirl.create(:pro_admin_user))).to be true
        end
      end

    end
  end

  describe '.view_hidden_and_embargoed' do
    it 'returns false if there is no user' do
      expect(User.view_hidden_and_embargoed?(nil)).to be false
    end

    it 'returns false if the user has no role' do
      expect(User.view_hidden_and_embargoed?(FactoryGirl.create(:user))).to be false
    end

    it 'returns false if the user is an admin user' do
      expect(User.view_hidden_and_embargoed?(FactoryGirl.create(:admin_user))).to be false
    end

    context 'with pro enabled' do

      it 'returns false if the user is an admin user' do
        with_feature_enabled(:alaveteli_pro) do
          expect(User.view_hidden_and_embargoed?(FactoryGirl.create(:admin_user))).to be false
        end
      end

      it 'returns true if pro is enabled and the user is a pro_admin user' do
        with_feature_enabled(:alaveteli_pro) do
          expect(User.view_hidden_and_embargoed?(FactoryGirl.create(:pro_admin_user)))
            .to be true
        end
      end
    end
  end

  describe '.info_request_events' do
    let(:user) { FactoryGirl.create(:user) }
    let(:info_request) { FactoryGirl.create(:info_request, :user => user) }
    let!(:response_event) do
      FactoryGirl.create(:response_event, :info_request => info_request)
    end
    let!(:comment_event) do
      FactoryGirl.create(:comment_event, :info_request => info_request)
    end
    let!(:resent_event) do
      FactoryGirl.create(:resent_event, :info_request => info_request)
    end

    it "returns events in descending created_at order" do
      expect(user.info_request_events.first).to eq resent_event
      expect(user.info_request_events.second).to eq comment_event
      expect(user.info_request_events.third).to eq response_event
    end

    it "returns all of the user's events" do
      # Note: there is a fourth "sent" event created automatically
      expect(user.info_request_events.count).to eq 4
    end
  end

  describe 'notifications' do
    it 'deletes associated notifications when destroyed' do
      notification = FactoryGirl.create(:notification)
      user = notification.user.reload
      expect(Notification.where(id: notification.id)).to exist
      user.destroy
      expect(Notification.where(id: notification.id)).not_to exist
    end
  end

  describe '#next_daily_summary_time' do
    let(:user) do
      FactoryGirl.create(:user, daily_summary_hour: 7,
                                daily_summary_minute: 56)
    end

    context "when the time is in the future" do
      let(:expected_time) { Time.zone.now.change(hour: 7, min: 56) }

      it "returns today's date with the daily summary time set" do
        time_travel_to(expected_time - 1.minute) do
          expect(user.next_daily_summary_time).
            to be_within(1.second).of(expected_time)
        end
      end
    end

    context "when the time is in the past" do
      let(:expected_time) { Time.zone.now.change(hour: 7, min: 56) + 1.day }

      it "returns tomorrow's date with the daily summary time set" do
        time_travel_to(Time.zone.now.change(hour: 7, min: 57)) do
          expect(user.next_daily_summary_time).
            to be_within(1.second).of(expected_time)
        end
      end
    end
  end

  describe '#daily_summary_time' do
    let(:user) do
      FactoryGirl.create(:user, daily_summary_hour: 7,
                                daily_summary_minute: 56)
    end

    it "returns the hour and minute of the user's daily summary time" do
      expected_hash = { hour: 7, min: 56 }
      expect(user.daily_summary_time).to eq(expected_hash)
    end
  end

  describe "setting daily_summary_time on new users" do
    let(:user) { FactoryGirl.create(:user) }
    let(:expected_time) { Time.zone.now.change(hour: 7, min: 57) }

    before do
      allow(User).
        to receive(:random_time_in_last_day).and_return(expected_time)
    end

    it "sets a random hour and minute on initialization" do
      expect(user.daily_summary_hour).to eq(7)
      expect(user.daily_summary_minute).to eq(57)
    end

    it "doesn't override the hour and minute if they're already set" do
      user = FactoryGirl.create(:user, daily_summary_hour: 9,
                                       daily_summary_minute: 15)
      expect(user.daily_summary_hour).to eq(9)
      expect(user.daily_summary_minute).to eq(15)
    end

    it "doesn't change the the hour and minute once they're set" do
      user.save!
      expect(user.daily_summary_hour).to eq(7)
      expect(user.daily_summary_minute).to eq(57)
    end
  end

  describe '#notification_frequency' do
    context 'when the user has :notifications' do
      let(:user) { FactoryGirl.create(:user) }

      before do
        AlaveteliFeatures.backend[:notifications].enable_actor user
      end

      it 'returns Notification::DAILY' do
        expect(user.notification_frequency).to eq (Notification::DAILY)
      end
    end

    context 'when the user doesnt have :notifications' do
      let(:user) { FactoryGirl.create(:user) }

      it 'returns Notification::INSTANTLY' do
        expect(user.notification_frequency).to eq (Notification::INSTANTLY)
      end
    end
  end

  describe "#notify" do
    let(:info_request_event) { FactoryGirl.create(:response_event) }
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

  describe "#flipper_id" do
    let(:user) { FactoryGirl.create(:user) }

    it "returns the user's id, prefixed with the class name" do
      expect(user.flipper_id).to eq("User;#{user.id}")
    end
  end

  describe 'role callbacks' do

    context 'with pro pricing enabled', feature: :pro_pricing do
      it 'creates pro account when pro role added' do
        user = FactoryGirl.build(:user)
        expect { user.add_role :pro }.to change(user, :pro_account).
          from(nil).to(ProAccount)
      end
    end

    context 'without pro pricing enabled' do
      it 'does not create pro account when pro role is added' do
        user = FactoryGirl.build(:user)
        expect { user.add_role :pro }.to_not change(user, :pro_account).
          from(nil)
      end
    end

  end

  describe 'update callbacks' do
    let(:user) { FactoryGirl.build(:user) }

    context 'changing email address of a pro user' do
      let(:pro_account) { double(:pro_account) }

      before do
        allow(user).to receive(:pro_account).and_return(pro_account)
        allow(user).to receive(:is_pro?).and_return(true)
        allow(user).to receive(:email_changed?).and_return(true)
      end

      it 'calls update_email_address on Pro Account' do
        expect(pro_account).to receive(:update_email_address)
        user.run_callbacks :update
      end

    end

  end

end

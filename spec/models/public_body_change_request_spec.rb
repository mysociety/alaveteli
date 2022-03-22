# == Schema Information
# Schema version: 20220210114052
#
# Table name: public_body_change_requests
#
#  id                :integer          not null, primary key
#  user_email        :string
#  user_name         :string
#  user_id           :integer
#  public_body_name  :text
#  public_body_id    :integer
#  public_body_email :string
#  source_url        :text
#  notes             :text
#  is_open           :boolean          default(TRUE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'spec_helper'

RSpec.describe PublicBodyChangeRequest do
  describe '#current_public_body_email' do
    subject { change_request.current_public_body_email }

    context 'when adding a public body' do
      let(:change_request) { FactoryBot.build(:add_body_request) }
      it { is_expected.to be_nil }
    end

    context 'when updating a public body' do
      let(:change_request) do
        body = FactoryBot.build(:public_body, request_email: 'prev@localhost')
        FactoryBot.create(:update_body_request,
                          public_body: body,
                          public_body_email: 'new@localhost')
      end

      it { is_expected.to eq('prev@localhost') }
    end
  end

  describe '#send_message' do
    subject { change_request.send_message }

    context 'when adding a public body' do
      let(:change_request) { FactoryBot.create(:add_body_request) }
      it { is_expected.to have_sent_email.matching_subject(/Add authority/) }
    end

    context 'when updating a public body' do
      let(:change_request) { FactoryBot.create(:update_body_request) }

      it do
        is_expected.to have_sent_email.matching_subject(/Update email address/)
      end
    end
  end
end

RSpec.describe PublicBodyChangeRequest, 'when validating' do

  it 'should not be valid without a public body name' do
    change_request = PublicBodyChangeRequest.new
    expect(change_request.valid?).to be false
    expect(change_request.errors[:public_body_name]).to eq(['Please enter the name of the authority'])
  end

  it 'should not be valid without a user name if there is no user' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body')
    expect(change_request.valid?).to be false
    expect(change_request.errors[:user_name]).to eq(['Please enter your name'])
  end

  it 'should not be valid without a user email address if there is no user' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body')
    expect(change_request.valid?).to be false
    expect(change_request.errors[:user_email]).to eq(['Please enter your email address'])
  end

  it 'should be valid with a user and no name or email address' do
    user = FactoryBot.build(:user)
    change_request = PublicBodyChangeRequest.new(:user => user,
                                                 :public_body_name => 'New Body')
    expect(change_request.valid?).to be true
  end

  it 'should validate the format of a user email address entered' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body',
                                                 :user_email => '@example.com')
    expect(change_request.valid?).to be false
    expect(change_request.errors[:user_email]).to eq(["Your email doesn't look like a valid address"])
  end

  it 'should validate the format of a public body email address entered' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'New Body',
                                                 :public_body_email => '@example.com')
    expect(change_request.valid?).to be false
    expect(change_request.errors[:public_body_email]).to eq(["The authority email doesn't look like a valid address"])
  end

end

RSpec.describe PublicBodyChangeRequest, 'get_user_name' do

  it 'should return the user_name field if there is no user association' do
    change_request = PublicBodyChangeRequest.new(:user_name => 'Test User')
    expect(change_request.get_user_name).to eq('Test User')
  end

  it 'should return the name of the associated user if there is one' do
    user = FactoryBot.build(:user)
    change_request = PublicBodyChangeRequest.new(:user => user)
    expect(change_request.get_user_name).to eq(user.name)
  end

end


RSpec.describe PublicBodyChangeRequest, 'get_user_email' do

  it 'should return the user_email field if there is no user association' do
    change_request = PublicBodyChangeRequest.new(:user_email => 'user@example.com')
    expect(change_request.get_user_email).to eq('user@example.com')
  end

  it 'should return the email of the associated user if there is one' do
    user = FactoryBot.build(:user)
    change_request = PublicBodyChangeRequest.new(:user => user)
    expect(change_request.get_user_email).to eq(user.email)
  end

end

RSpec.describe PublicBodyChangeRequest, '.new_body_requests' do
  let(:new_request) { FactoryBot.create(:add_body_request) }
  let(:update_request) { FactoryBot.create(:update_body_request) }

  it "returns requests where the public_body_id is nil" do
    expect(PublicBodyChangeRequest.new_body_requests).
      to eq([new_request])
  end
end

RSpec.describe PublicBodyChangeRequest, '.body_update_requests' do
  let(:new_request) { FactoryBot.create(:add_body_request) }
  let(:update_request) { FactoryBot.create(:update_body_request) }

  it "returns requests where the public_body_id is not nil" do
    expect(PublicBodyChangeRequest.body_update_requests).to eq([update_request])
  end
end

RSpec.describe PublicBodyChangeRequest, '.open' do
  let(:open_request) do
    FactoryBot.create(:update_body_request, :is_open => true)
  end

  let(:closed_request) do
    FactoryBot.create(:update_body_request, :is_open => false)
  end

  it "returns requests where the is_open is true" do
    expect(PublicBodyChangeRequest.open).to eq([open_request])
  end
end

RSpec.describe PublicBodyChangeRequest, 'get_public_body_name' do

  it 'should return the public_body_name field if there is no public body association' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'Test Authority')
    expect(change_request.get_public_body_name).to eq('Test Authority')
  end

  it 'should return the name of the associated public body if there is one' do
    public_body = FactoryBot.build(:public_body)
    change_request = PublicBodyChangeRequest.new(:public_body => public_body)
    expect(change_request.get_public_body_name).to eq(public_body.name)
  end

end

RSpec.describe PublicBodyChangeRequest, 'when creating a comment for the associated public body' do

  it 'should include requesting user, source_url and notes' do
    change_request = PublicBodyChangeRequest.new(:user_name => 'Test User',
                                                 :user_email => 'test@example.com',
                                                 :source_url => 'http://www.example.com',
                                                 :notes => 'Some notes')
    expected = "Requested by: Test User (test@example.com)\nSource URL: http://www.example.com\nNotes: Some notes"
    expect(change_request.comment_for_public_body).to eq(expected)
  end

end

RSpec.describe PublicBodyChangeRequest, '#request_subject' do

  context 'requesting a new authority' do

    it 'returns an appropriate subject line' do
      change_request = PublicBodyChangeRequest.new(:public_body_name => 'Test')
      expect(change_request.request_subject).
        to eq('Add authority - Test')
    end

    it 'does not HTML escape the authority name' do
      change_request =
        PublicBodyChangeRequest.new(:public_body_name => "Test's")
      expect(change_request.request_subject).
        to eq('Add authority - Test\'s')
    end

    it 'does not mark subject line with unescaped text as html_safe' do
      change_request =
        PublicBodyChangeRequest.new(:public_body_name => "Test's")
      expect(change_request.request_subject.html_safe?).to eq(false)
    end

  end

  context 'updating an existing authority' do

    it 'returns an appropriate subject line' do
      public_body = FactoryBot.build(:public_body)
      change_request = PublicBodyChangeRequest.new(:public_body => public_body)
      expect(change_request.request_subject).
        to eq("Update email address - #{public_body.name}")
    end

    it 'does not HTML escape the authority name' do
      public_body = FactoryBot.build(:public_body, name: "Test's")
      change_request = PublicBodyChangeRequest.new(:public_body => public_body)
      expect(change_request.request_subject).
        to eq('Update email address - Test\'s')
    end

  end

end

RSpec.describe PublicBodyChangeRequest, '#add_body_request?' do

  it 'returns false if there is an associated public_body' do
    public_body = FactoryBot.build(:public_body)
    change_request = PublicBodyChangeRequest.new(:public_body => public_body)
    expect(change_request.add_body_request?).to eq(false)
  end

  it 'returns true if there is no associated public_body' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'Test')
    expect(change_request.add_body_request?).to eq(true)
  end

end

RSpec.describe PublicBodyChangeRequest, 'when creating a default subject for a response email' do

  it 'should create an appropriate subject for a request to add a body' do
    change_request = PublicBodyChangeRequest.new(:public_body_name => 'Test Body')
    expect(change_request.default_response_subject).
      to eq('Re: Add authority - Test Body')
  end

  it 'should create an appropriate subject for a request to update an email address' do
    public_body = FactoryBot.build(:public_body)
    change_request = PublicBodyChangeRequest.new(:public_body => public_body)
    expect(change_request.default_response_subject).
      to eq("Re: Update email address - #{public_body.name}")
  end

end

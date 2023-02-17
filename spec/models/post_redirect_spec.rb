# == Schema Information
# Schema version: 20210114161442
#
# Table name: post_redirects
#
#  id                 :integer          not null, primary key
#  token              :text             not null
#  uri                :text             not null
#  post_params_yaml   :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  email_token        :text             not null
#  reason_params_yaml :text
#  user_id            :integer
#  circumstance       :text             default("normal"), not null
#

require 'spec_helper'

RSpec.describe PostRedirect do

  describe '.generate_verifiable_token' do
    subject do
      described_class.generate_verifiable_token(
        user: user, circumstance: 'normal'
      )
    end

    let(:user) { double(:user, id: 101, login_token: 'abc') }

    it 'matches expected token' do
      is_expected.to eq(
        described_class.verifier.generate(
          { user_id: user.id, login_token: user.login_token },
          purpose: 'normal'
        )
      )
    end
  end

  describe '.verifier' do
    subject { described_class.verifier }
    it { is_expected.to be_a(ActiveSupport::MessageVerifier) }
  end

  describe '#valid?' do

    it 'is false if an invalid circumstance is provided' do
      pr = PostRedirect.new(circumstance: 'invalid')
      expect(pr).to_not be_valid
    end

  end

  describe '#email_token_valid?' do

    subject { post_redirect.email_token_valid? }

    # Using attributes_for as PostRedirect redirect assigns attributes in
    # after_initialize callbacks. FactoryBot doesn't handle this correctly
    let!(:post_redirect) { PostRedirect.create(attributes.merge(user: user)) }
    let(:user) { FactoryBot.create(:user) }

    context 'when an old non-message verifier tokens' do
      let(:attributes) do
        FactoryBot.attributes_for(
          :post_redirect,
          circumstance: 'change_email',
          email_token: 'ABC'
        )
      end

      it { is_expected.to eq true }
    end

    context 'when user login token has not changed' do
      let(:attributes) do
        FactoryBot.attributes_for(:post_redirect, circumstance: 'change_email')
      end

      it { is_expected.to eq true }
    end

    context 'when user login token has changed' do
      let(:attributes) do
        FactoryBot.attributes_for(:post_redirect, circumstance: 'change_email')
      end

      before { user.update(email: 'new@email') }

      it { is_expected.to eq false }
    end

  end

end

RSpec.describe PostRedirect, " when constructing" do
  before do
  end

  it "should generate a different token from email token" do
    pr = PostRedirect.new
    expect(pr.token).not_to eq(pr.email_token)
  end

  it "should generate a different token each time" do
    pr_1 = PostRedirect.new
    pr_2 = PostRedirect.new
    expect(pr_1.token).not_to be_nil
    expect(pr_2.token).not_to be_nil
    expect(pr_1.token).not_to eq(pr_2.token)
  end

  it "should generate a different email each time" do
    pr_1 = PostRedirect.new
    pr_2 = PostRedirect.new
    expect(pr_1.email_token).not_to be_nil
    expect(pr_2.email_token).not_to be_nil
    expect(pr_1.email_token).not_to eq(pr_2.email_token)
  end

  it "should generate a URL friendly token" do
    pr = PostRedirect.new
    expect(pr.token).to match(/[a-z0-9]+/);
  end

  it "should generate an email friendly email token" do
    pr = PostRedirect.new
    expect(pr.email_token).to match(/[a-z0-9]+/);
  end

  context 'when normal circumstance' do
    it 'should call not .generate_verifiable_token' do
      allow(PostRedirect).to receive(:generate_verifiable_token)
      PostRedirect.new(circumstance: 'normal')
      expect(PostRedirect).to_not receive(:generate_verifiable_token)
    end
  end

  context 'when not normal circumstance' do
    it 'should call .generate_verifiable_token' do
      allow(PostRedirect).to receive(:generate_verifiable_token)

      user = FactoryBot.build(:user, login_token: 'abc')
      pr = PostRedirect.new(user: user, circumstance: 'change_password')

      expect(PostRedirect).to receive(:generate_verifiable_token)
      expect(pr.email_token).to eq described_class.generate_verifiable_token(
        user: user, circumstance: 'change_password'
      )
    end
  end
end

RSpec.describe PostRedirect, " when accessing values" do
  before do
  end

  it "should convert post parameters into YAML and back successfully" do
    pr = PostRedirect.new
    example_post_params = { foo: 'this is stuff', bar: 83, humbug: "yikes!!!" }
    pr.post_params = example_post_params
    expect(pr.post_params_yaml).to eq(example_post_params.to_yaml)
    expect(pr.post_params).to eq(example_post_params)
  end

  it "should convert reason parameters into YAML and back successfully" do
    pr = PostRedirect.new
    example_reason_params = { foo: 'this is stuff', bar: 83, humbug: "yikes!!!" }
    pr.reason_params = example_reason_params
    expect(pr.reason_params_yaml).to eq(example_reason_params.to_yaml)
    expect(pr.reason_params).to eq(example_reason_params)
  end

  it "should restore UTF8-heavy params stored under ruby 1.8 as UTF-8" do
    pr = PostRedirect.new
    utf8_params = "--- \n:foo: !binary |\n  0KLQvtCz0LDRiCDR\n"
    pr.reason_params_yaml = utf8_params
    expect(pr.reason_params[:foo].encoding.to_s).to eq('UTF-8')
  end
end

require 'spec_helper'

RSpec.describe PendingTwoFactorSignIn do
  subject(:pending) { described_class.new(session) }

  let(:session) { {} }
  let(:user) { FactoryBot.create(:user, :enable_totp) }
  let(:post_redirect) { FactoryBot.create(:post_redirect) }

  describe '#start' do
    before do
      pending.start(user: user, remember_me: true, post_redirect: post_redirect)
    end

    it 'stores the user id' do
      expect(session[:pending_2fa_user_id]).to eq(user.id)
    end

    it 'stores a started-at timestamp as an epoch integer' do
      expect(session[:pending_2fa_started_at]).
        to be_within(1).of(Time.zone.now.to_i)
    end

    it 'stores the remember-me flag' do
      expect(session[:pending_2fa_remember_me]).to eq(true)
    end

    it 'stores the post redirect token' do
      expect(session[:pending_2fa_post_redirect_token]).
        to eq(post_redirect.token)
    end
  end

  describe '#user' do
    it 'loads the user from the stored id' do
      session[:pending_2fa_user_id] = user.id
      expect(pending.user).to eq(user)
    end

    it 'is nil without a stored id' do
      expect(pending.user).to be_nil
    end
  end

  describe '#post_redirect' do
    it 'loads the post redirect from the stored token' do
      session[:pending_2fa_post_redirect_token] = post_redirect.token
      expect(pending.post_redirect).to eq(post_redirect)
    end

    it 'is nil without a stored token' do
      expect(pending.post_redirect).to be_nil
    end
  end

  describe '#remember_me' do
    it 'reads it back from the session' do
      session[:pending_2fa_remember_me] = false
      expect(pending.remember_me).to eq(false)
    end
  end

  describe '#expired?' do
    it 'is true when no timestamp is stored' do
      expect(pending.expired?).to eq(true)
    end

    it 'is false within the TTL' do
      session[:pending_2fa_started_at] = Time.zone.now.to_i
      expect(pending.expired?).to eq(false)
    end

    it 'is true past the TTL' do
      session[:pending_2fa_started_at] =
        (described_class::TTL + 1.minute).ago.to_i
      expect(pending.expired?).to eq(true)
    end
  end

  describe '#active?' do
    it 'is true for a TOTP user within the TTL' do
      pending.start(user: user, remember_me: false,
                    post_redirect: post_redirect)
      expect(pending.active?).to eq(true)
    end

    it 'is false for a HOTP user' do
      hotp_user = FactoryBot.create(:user, :enable_hotp)
      pending.start(user: hotp_user, remember_me: false,
                    post_redirect: post_redirect)
      expect(pending.active?).to eq(false)
    end

    it 'is false past the TTL' do
      pending.start(user: user, remember_me: false,
                    post_redirect: post_redirect)
      session[:pending_2fa_started_at] =
        (described_class::TTL + 1.minute).ago.to_i
      expect(pending.active?).to eq(false)
    end

    it 'is false without a pending user' do
      expect(pending.active?).to eq(false)
    end
  end

  describe '#clear' do
    it 'removes every pending key' do
      pending.start(user: user, remember_me: true, post_redirect: post_redirect)
      pending.clear
      expect(session).to be_empty
    end
  end
end

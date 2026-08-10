require 'spec_helper'

RSpec.describe OtpEnrolment do
  let(:user) { FactoryBot.build(:user, email: 'alice@example.com') }
  let(:secret) { ROTP::Base32.random }
  let(:valid_code) { ROTP::TOTP.new(secret).now }
  let(:invalid_code) { valid_code == '000000' ? '000001' : '000000' }
  let(:enrolment) { OtpEnrolment.new(user: user, secret: secret) }

  describe '#secret' do
    it 'returns the candidate secret' do
      expect(enrolment.secret).to eq(secret)
    end
  end

  describe '#provisioning_uri' do
    before do
      allow(AlaveteliConfiguration).
        to receive(:site_name).and_return('Example Site')
    end

    it 'builds an otpauth TOTP URI for the user' do
      expect(enrolment.provisioning_uri).to start_with('otpauth://totp/')
    end

    it 'embeds the user email' do
      expect(enrolment.provisioning_uri).
        to include(CGI.escape(user.email))
    end

    it 'uses the configured site name as the issuer' do
      expect(enrolment.provisioning_uri).
        to include('issuer=Example%20Site')
    end

    it 'encodes the candidate secret' do
      expect(enrolment.provisioning_uri).to include("secret=#{secret}")
    end
  end

  describe '#valid?' do
    it 'is true when the otp_code matches the secret' do
      enrolment.otp_code = valid_code
      expect(enrolment.valid?).to eq(true)
    end

    it 'is false when the otp_code does not match the secret' do
      enrolment.otp_code = invalid_code
      expect(enrolment.valid?).to eq(false)
    end

    it 'is false when otp_code is blank' do
      enrolment.otp_code = ''
      expect(enrolment.valid?).to eq(false)
    end

    it 'records an error on :otp_code when the code does not match' do
      enrolment.otp_code = invalid_code
      enrolment.valid?
      expect(enrolment.errors[:otp_code]).to be_present
    end

    context 'with a code submitted just after its step ended' do
      let(:period_start) { Time.utc(2026, 8, 5, 10, 0, 0) }
      let(:period_end) { period_start + 30.seconds }
      let(:window_closes) { period_end + User::OneTimePassword::DRIFT }

      before do
        travel_to(period_end - 1.second) do
          enrolment.otp_code = ROTP::TOTP.new(secret).now
        end
      end

      it 'is true inside the drift window' do
        travel_to(window_closes - 1.second) do
          expect(enrolment.valid?).to eq(true)
        end
      end

      it 'is false once the drift window has closed' do
        travel_to(window_closes) do
          expect(enrolment.valid?).to eq(false)
        end
      end
    end
  end

  describe '#save' do
    let(:user) { FactoryBot.create(:user) }

    context 'with a code that matches the secret' do
      before { enrolment.otp_code = valid_code }

      it 'persists the candidate as the otp_secret_key' do
        enrolment.save
        expect(user.reload.otp_secret_key).to eq(secret)
      end

      it 'nulls otp_counter so the user is TOTP' do
        user.update_columns(otp_counter: 1)
        enrolment.save
        expect(user.reload.otp_counter).to be_nil
      end

      it 'sets otp_enabled to true' do
        enrolment.save
        expect(user.reload.otp_enabled).to eq(true)
      end

      it 'stamps otp_enabled_at with the current time' do
        freeze_time = Time.zone.parse('2026-05-18 12:00:00')

        travel_to(freeze_time) do
          enrolment.otp_code = ROTP::TOTP.new(secret).now
          enrolment.save
        end

        expect(user.reload.otp_enabled_at).
          to be_within(1.second).of(freeze_time)
      end

      it 'returns true' do
        expect(enrolment.save).to eq(true)
      end

      it 'issues backup codes alongside their timestamp' do
        enrolment.save
        user.reload
        expect(user.otp_backup_codes.size).to eq(12)
        expect(user.otp_backup_codes_generated_at).to be_present
      end

      it 'exposes the plaintext backup codes after saving' do
        enrolment.save
        expect(enrolment.backup_codes.size).to eq(12)
        expect(enrolment.backup_codes).to all(match(/\A\d{6}\z/))
      end
    end

    context 'with a code that does not match' do
      before { enrolment.otp_code = invalid_code }

      it 'returns false' do
        expect(enrolment.save).to eq(false)
      end

      it 'does not modify the persisted user record' do
        original_secret = user.otp_secret_key
        original_counter = user.otp_counter
        original_enabled = user.otp_enabled

        enrolment.save

        user.reload
        expect(user.otp_secret_key).to eq(original_secret)
        expect(user.otp_counter).to eq(original_counter)
        expect(user.otp_enabled).to eq(original_enabled)
      end

      it 'populates an error on :otp_code' do
        enrolment.save
        expect(enrolment.errors[:otp_code]).to be_present
      end

      it 'does not issue backup codes' do
        enrolment.save
        user.reload
        expect(user.otp_backup_codes).to be_empty
        expect(user.otp_backup_codes_generated_at).to be_nil
        expect(enrolment.backup_codes).to be_nil
      end
    end

    context 'when the underlying user save returns false' do
      before { enrolment.otp_code = valid_code }

      it 'returns false rather than reporting success' do
        allow(user).to receive(:save).and_return(false)
        expect(enrolment.save).to eq(false)
      end

      it 'does not expose backup codes' do
        allow(user).to receive(:save).and_return(false)
        enrolment.save
        expect(enrolment.backup_codes).to be_nil
      end
    end
  end
end

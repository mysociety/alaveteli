require 'spec_helper'

def validator_with_user_and_params(user, params = {})
  validator = ChangeEmailValidator.new(params)
  validator.logged_in_user = user
  validator
end

RSpec.describe ChangeEmailValidator do
  let(:user) { FactoryBot.create(:user) }

  describe '#old_email' do
    it 'must have an old email' do
      params = { old_email: nil,
                 new_email: 'new@example.com',
                 user_circumstance: 'change_email',
                 password: 'jonespassword' }
      validator = validator_with_user_and_params(user, params)

      msg = 'Please enter your old email address'
      validator.valid?
      expect(validator.errors[:old_email]).to include(msg)
    end

    it 'must be a valid email' do
      params = { old_email: 'old',
                 new_email: 'new@example.com',
                 user_circumstance: 'change_email',
                 password: 'jonespassword' }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      msg = "Old email doesn't look like a valid address"
      expect(validator.errors[:old_email]).to include(msg)
    end

    it 'must have the same email as the logged in user' do
      params = { old_email: user.email,
                 new_email: 'new@example.com',
                 user_circumstance: 'change_email',
                 password: 'jonespassword' }
      validator = validator_with_user_and_params(user, params)
      validator.logged_in_user = FactoryBot.build(:user)
      validator.valid?
      msg = "Old email address isn't the same as the address of the account you are logged in with"
      expect(validator.errors[:old_email]).to include(msg)
    end
  end

  describe '#new_email' do
    it 'must have a new email' do
      params = { old_email: user.email,
                 new_email: nil,
                 user_circumstance: 'change_email',
                 password: 'jonespassword' }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      msg = 'Please enter your new email address'
      expect(validator.errors[:new_email]).to include(msg)
    end

    it 'must be a valid email' do
      params = { old_email: user.email,
                 new_email: 'new',
                 user_circumstance: 'change_email',
                 password: 'jonespassword' }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      msg = "New email doesn't look like a valid address"
      expect(validator.errors[:new_email]).to include(msg)
    end
  end

  describe '#confirmed_email' do
    let(:post_redirect) do
      FactoryBot.create(
        :post_redirect,
        user: user,
        circumstance: 'change_email',
        post_params: {
          'signchangeemail' => {
            'old_email' => user.email,
            'new_email' => 'confirmed@example.com'
          }
        }
      )
    end

    it 'rejects new_email that differs from confirmed_email' do
      params = { old_email: user.email,
                 new_email: 'different@example.com',
                 user_circumstance: 'change_email',
                 post_redirect_token: post_redirect.token }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      msg = 'New email address does not match the address that was confirmed'
      expect(validator.errors[:new_email]).to include(msg)
    end

    it 'accepts new_email that matches confirmed_email' do
      params = { old_email: user.email,
                 new_email: 'confirmed@example.com',
                 user_circumstance: 'change_email',
                 post_redirect_token: post_redirect.token }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      expect(validator.errors[:new_email]).to be_empty
    end

    it 'rejects token belonging to a different user' do
      other_user = FactoryBot.create(:user)
      params = { old_email: other_user.email,
                 new_email: 'confirmed@example.com',
                 user_circumstance: 'change_email',
                 post_redirect_token: post_redirect.token }
      validator = validator_with_user_and_params(other_user, params)
      validator.valid?
      msg = 'New email address does not match the address that was confirmed'
      expect(validator.errors[:new_email]).to include(msg)
    end
  end

  describe '#password' do
    it 'password_and_format_of_email validation fails when password is nil' do
      params = { old_email: user.email,
                 new_email: 'new@example.com',
                 password: nil }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      msg = 'Please enter your password'
      expect(validator.errors[:password]).to include(msg)
    end

    it 'does not require a password if changing email' do
      params = { old_email: user.email,
                 new_email: 'new@example.com',
                 user_circumstance: 'change_email',
                 password: '' }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      expect(validator.errors[:password].size).to eq(0)
    end

    it 'must have a password if not changing email' do
      params = { old_email: user.email,
                 new_email: 'new@example.com',
                 user_circumstance: 'unknown',
                 password: '' }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      msg = 'Please enter your password'
      expect(validator.errors[:password]).to include(msg)
    end

    it 'must be the correct password' do
      params = { old_email: user.email,
                 new_email: 'new@example.com',
                 password: 'incorrectpass' }
      validator = validator_with_user_and_params(user, params)
      validator.valid?
      msg = 'Password is not correct'
      expect(validator.errors[:password]).to include(msg)
    end
  end
end

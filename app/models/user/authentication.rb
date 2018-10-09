require 'bcrypt'
require 'digest/sha1'

module User::Authentication
  extend ActiveSupport::Concern

  included do
    attr_reader :password
    attr_accessor :password_confirmation

    scope :sha1, lambda {
      where("users.salt IS NOT NULL AND users.hashed_password NOT LIKE '$2a$%'")
    }

    validate do |user|
      if user.hashed_password.blank?
        user.errors.add(:password, _('Please enter a password'))
      end
    end

    validates :password, length: {
      minimum: 12,
      allow_blank: true,
      message: _('Password is too short (minimum is 12 characters)')
    }
    validates :password, length: {
      maximum: 72,
      allow_blank: true,
      message: _('Password is too long (maximum is 72 characters)')
    }
    validates :password, confirmation: {
      allow_blank: true,
      message: _('Please enter the same password twice')
    }
  end

  module ClassMethods
    def sha1_password(password, salt)
      string_to_hash = password + salt.to_s
      Digest::SHA1.hexdigest(string_to_hash)
    end
  end

  def password=(pwd)
    if pwd.blank?
      self.hashed_password = nil
    else
      @password = pwd
      self.hashed_password = BCrypt::Password.create(password)
    end
  end

  def has_this_password?(password)
    begin
      # check if bcrypt hashed_password matches password
      bcrypt_password = BCrypt::Password.new(hashed_password)
      return true if bcrypt_password == password
    rescue BCrypt::Errors::InvalidHash
    end

    sha1_password = User.sha1_password(password, salt)
    if bcrypt_password == sha1_password # password been rehashed
      attempt_password_upgrade(password)
      true

    elsif hashed_password == sha1_password # password not rehashed
      attempt_password_upgrade(password)
      true

    else # password invalid
      false
    end
  end

  private

  def attempt_password_upgrade(password)
    # don't upgrade if record has been modified as we're skipping validation
    # below
    return if changed?

    self.password = password
    self.salt = nil

    save(validate: false)
  end
end

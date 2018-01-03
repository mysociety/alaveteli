require 'bcrypt'
require 'digest/sha1'

module User::Authenication
  extend ActiveSupport::Concern

  included do
    attr_reader :password
    attr_accessor :password_confirmation

    validates_presence_of :hashed_password,
                          message: _('Please enter a password')
    validates_confirmation_of :password,
                              message: _('Please enter the same password twice')
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
      true

    elsif hashed_password == sha1_password # password not rehashed
      true

    else # password invalid
      false
    end
  end
end

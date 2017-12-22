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
    def encrypted_password(password, salt)
      string_to_hash = password + salt.to_s # TODO: need to add a secret here too?
      Digest::SHA1.hexdigest(string_to_hash)
    end
  end

  def password=(pwd)
    @password = pwd
    if pwd.blank?
      self.hashed_password = nil
      return
    end
    create_new_salt
    self.hashed_password = User.encrypted_password(password, salt)
  end

  def has_this_password?(password)
    expected_password = User.encrypted_password(password, salt)
    hashed_password == expected_password
  end

  private

  def create_new_salt
    self.salt = object_id.to_s + rand.to_s
  end
end

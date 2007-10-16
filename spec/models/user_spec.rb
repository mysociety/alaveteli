require File.dirname(__FILE__) + '/../spec_helper'

describe User, " when authenticating" do

  before do
    @user = User.new 
  end
  
  it "should create a hashed password when the password is set" do
    @user.hashed_password.should be_nil
    @user.password = "a test password"
    @user.hashed_password.should_not be_nil
  end

end
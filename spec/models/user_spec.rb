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

describe User, " when saving" do
    before do
        @user = User.new 
    end

    it "should not save without setting some parameters" do
        lambda { @user.save! }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not save with misformatted email" do
        @user.name = "Mr. Silly"
        @user.password = "insecurepassword"  
        @user.email = "mousefooble"
        lambda { @user.save! }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "should not save with no password" do
        @user.name = "Mr. Silly"
        @user.password = ""  
        @user.email = "francis@mysociety.org"
        lambda { @user.save! }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "should save with reasonable name, password and email" do
        @user.name = "Mr. Silly"
        @user.password = "insecurepassword"  
        @user.email = "francis@mysociety.org"
        @user.save!
    end
end


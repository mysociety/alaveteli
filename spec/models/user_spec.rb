require File.dirname(__FILE__) + '/../spec_helper'

describe User, " when authenticating" do
    before do
        @empty_user = User.new 

        @full_user = User.new
        @full_user.name = "Sensible User"
        @full_user.password = "foolishpassword"
        @full_user.email = "sensible@localhost"
        @full_user.save
    end

    it "should create a hashed password when the password is set" do
        @empty_user.hashed_password.should be_nil
        @empty_user.password = "a test password"
        @empty_user.hashed_password.should_not be_nil
    end

    it "should not find the user when given the wrong password" do
        found_user = User.authenticate("sensible@localhost", "iownzyou")
        found_user.should be_nil
    end

    it "should not find the user when given the wrong email" do
        found_user = User.authenticate("soccer@localhost", "foolishpassword")
        found_user.should be_nil
    end

    it "should find the user when given the right email and password" do
        found_user = User.authenticate("sensible@localhost", "foolishpassword")
        found_user.should == (@full_user)
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
        @user.email = "silly@localhost"
        lambda { @user.save! }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it "should save with reasonable name, password and email" do
        @user.name = "Mr. Reasonable"
        @user.password = "insecurepassword"  
        @user.email = "reasonable@localhost"
        @user.save!
    end
end


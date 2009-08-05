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

    it "should have errors when given the wrong password" do
        found_user = User.authenticate_from_form({ :email => "sensible@localhost", :password => "iownzyou" })
        found_user.errors.size.should > 0
    end

    it "should not find the user when given the wrong email" do
        found_user = User.authenticate_from_form( { :email => "soccer@localhost", :password => "foolishpassword" })
        found_user.errors.size.should > 0
    end

    it "should find the user when given the right email and password" do
        found_user = User.authenticate_from_form( { :email => "sensible@localhost", :password => "foolishpassword" })
        found_user.errors.size.should == 0
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
        @user.should have(1).error_on(:email)
    end

    it "should not allow an email address as a name" do
        @user.name = "silly@example.com"
        @user.email = "silly@example.com"
        @user.password = "insecurepassword"  
        @user.should have(1).error_on(:name)
    end

    it "should not save with no password" do
        @user.name = "Mr. Silly"
        @user.password = ""  
        @user.email = "silly@localhost"
        @user.should have(1).error_on(:hashed_password)
    end

    it "should save with reasonable name, password and email" do
        @user.name = "Mr. Reasonable"
        @user.password = "insecurepassword"  
        @user.email = "reasonable@localhost"
        @user.save!
    end

    it "should let you make two users with same name" do
        @user.name = "Mr. Flobble"
        @user.password = "insecurepassword"  
        @user.email = "flobble@localhost"
        @user.save!

        @user2 = User.new 
        @user2.name = "Mr. Flobble"
        @user2.password = "insecurepassword"  
        @user2.email = "flobble2@localhost"
        @user2.save!
    end
    
    it 'should mark the model for reindexing in xapian if the no_xapian_reindex flag is set to false' do
        @user.name = "Mr. First"
        @user.password = "insecurepassword"  
        @user.email = "reasonable@localhost"
        @user.no_xapian_reindex = false
        @user.should_receive(:xapian_mark_needs_index)
        @user.save!
    end
    
    it 'should mark the model for reindexing in xapian if the no_xapian_reindex flag is not set'  do
        @user.name = "Mr. Second"
        @user.password = "insecurepassword"  
        @user.email = "reasonable@localhost"
        @user.no_xapian_reindex = nil
        @user.should_receive(:xapian_mark_needs_index)
        @user.save!
    end
       
    it 'should not mark the model for reindexing in xapian if the no_xapian_reindex flag is set' do 
        @user.name = "Mr. Third"
        @user.password = "insecurepassword"  
        @user.email = "reasonable@localhost"
        @user.no_xapian_reindex = true
        @user.should_not_receive(:xapian_mark_needs_index)
        @user.save!
    end

end


describe User, "when reindexing referencing models" do 

    before do 
        @request_event = mock_model(InfoRequestEvent, :xapian_mark_needs_index => true)
        @request = mock_model(InfoRequest, :info_request_events => [@request_event])
        @comment_event = mock_model(InfoRequestEvent, :xapian_mark_needs_index => true)
        @comment = mock_model(Comment, :info_request_events => [@comment_event])
        @user = User.new(:comments => [@comment], :info_requests => [@request])
    end
    
    it 'should reindex events associated with that user\'s comments when URL changes' do 
        @user.stub!(:changes).and_return({'url_name' => 1})
        @comment_event.should_receive(:xapian_mark_needs_index)
        @user.reindex_referencing_models
    end
    
    it 'should reindex events associated with that user\'s requests when URL changes' do 
        @user.stub!(:changes).and_return({'url_name' => 1})
        @request_event.should_receive(:xapian_mark_needs_index)
        @user.reindex_referencing_models
    end
    
    describe 'when no_xapian_reindex is set' do 
        before do 
            @user.no_xapian_reindex = true
        end
            
        it 'should not reindex events associated with that user\'s comments when URL changes' do 
            @user.stub!(:changes).and_return({'url_name' => 1})
            @comment_event.should_not_receive(:xapian_mark_needs_index)
            @user.reindex_referencing_models
        end
        
        it 'should not reindex events associated with that user\'s requests when URL changes' do 
        @user.stub!(:changes).and_return({'url_name' => 1})
        @request_event.should_not_receive(:xapian_mark_needs_index)
            @user.reindex_referencing_models
        end
    
    end
    
end

describe User, "when checking abilities" do
    fixtures :users

    before do
        @user = users(:bob_smith_user)
    end

    it "should not get admin links" do
        @user.admin_page_links?.should be_false
    end

    it "should be able to file requests" do
        @user.can_file_requests?.should be_true
    end

end

describe User, 'when asked if a user owns every request' do 
    
    before do 
        @mock_user = mock_model(User)
    end
    
    it 'should return false if no user is passed' do 
        User.owns_every_request?(nil).should be_false
    end
    
    it 'should return true if the user has "requires admin" power' do 
        @mock_user.stub!(:owns_every_request?).and_return true
        User.owns_every_request?(@mock_user).should be_true
    end
    
    it 'should return false if the user does not have "requires admin" power' do 
        @mock_user.stub!(:owns_every_request?).and_return false
        User.owns_every_request?(@mock_user).should be_false
    end
    
end

describe User, " when making name and email address" do
    it "should generate a name and email" do
        @user = User.new
        @user.name = "Sensible User"
        @user.email = "sensible@localhost"

        @user.name_and_email.should == "Sensible User <sensible@localhost>"
    end

    it "should quote name and email with funny characters in the name" do
        @user = User.new
        @user.name = "Silly @ User"
        @user.email = "silly@localhost"

        @user.name_and_email.should == "\"Silly @ User\" <silly@localhost>"
    end
end


describe User, " when setting a profile photo" do
    before do
        @user = User.new
        @user.name = "Sensible User"
        @user.email = "sensible@localhost"
        @user.password = "sensiblepassword"
    end

    it "should attach it to the user" do
        data = load_image_fixture("parrot.png")
        profile_photo = ProfilePhoto.new(:data => data)
        @user.set_profile_photo(profile_photo)
        profile_photo.user.should == @user
    end

#    it "should destroy old photos being replaced" do
#        ProfilePhoto.count.should == 0
#
#        data_1 = load_image_fixture("parrot.png")
#        profile_photo_1 = ProfilePhoto.new(:data => data_1)
#        data_2 = load_image_fixture("parrot.jpg")
#        profile_photo_2 = ProfilePhoto.new(:data => data_2)
#
#        @user.set_profile_photo(profile_photo_1)
#        @user.save!
#        ProfilePhoto.count.should == 1
#        @user.set_profile_photo(profile_photo_2)
#        @user.save!
#        ProfilePhoto.count.should == 1
#    end
end


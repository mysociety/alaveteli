require File.dirname(__FILE__) + '/../spec_helper'

describe ProfilePhoto, "when constructing a new photo" do 

    before do 
        #@request_event = mock_model(InfoRequestEvent, :xapian_mark_needs_index => true)
        #@request = mock_model(InfoRequest, :info_request_events => [@request_event])
        #@user = mock_model(User)
    end
    
    it 'should take no image as invalid' do
        profile_photo = ProfilePhoto.new(:data => nil)
        profile_photo.valid?.should == false
    end

    it 'should take bad binary data as invalid' do
        profile_photo = ProfilePhoto.new(:data => 'blahblahblah')
        profile_photo.valid?.should == false
    end

    it 'should accept and convert a PNG to right size' do 
        data = load_image_fixture("parrot.png")
        profile_photo = ProfilePhoto.new(:data => data, :user => mock_model(User, :valid? => true))
        profile_photo.valid?.should == true
        profile_photo.image.format.should == 'PNG'
        profile_photo.image.columns.should == 96
        profile_photo.image.rows.should == 96
    end

    it 'should accept and convert a JPEG to right format and size' do 
        data = load_image_fixture("parrot.jpg")
        profile_photo = ProfilePhoto.new(:data => data, :user => mock_model(User, :valid? => true))
        profile_photo.valid?.should == true
        profile_photo.image.format.should == 'PNG'
        profile_photo.image.columns.should == 96
        profile_photo.image.rows.should == 96
    end
     
end


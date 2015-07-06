# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: profile_photos
#
#  id      :integer          not null, primary key
#  data    :binary           not null
#  user_id :integer
#  draft   :boolean          default(FALSE), not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ProfilePhoto, "when constructing a new photo" do

    before do
        @mock_user = mock_model(User)
    end

    it 'should take no image as invalid' do
        profile_photo = ProfilePhoto.new(:data => nil, :user => @mock_user)
        profile_photo.valid?.should == false
    end

    it 'should take bad binary data as invalid' do
        profile_photo = ProfilePhoto.new(:data => 'blahblahblah', :user => @mock_user)
        profile_photo.valid?.should == false
    end

    it 'should translate a no image error message' do
        I18n.with_locale(:es) do
            profile_photo = ProfilePhoto.new(:data => nil, :user => @mock_user)
            profile_photo.valid?.should == false
            profile_photo.errors[:data].should == ['Por favor elige el fichero que contiene tu foto']
        end
    end

    it 'should accept and convert a PNG to right size' do
        data = load_file_fixture("parrot.png")
        profile_photo = ProfilePhoto.new(:data => data, :user => @mock_user)
        profile_photo.valid?.should == true
        profile_photo.image.format.should == 'PNG'
        profile_photo.image.columns.should == 96
        profile_photo.image.rows.should == 96
    end

    it 'should accept and convert a JPEG to right format and size' do
        data = load_file_fixture("parrot.jpg")
        profile_photo = ProfilePhoto.new(:data => data, :user => @mock_user)
        profile_photo.valid?.should == true
        profile_photo.image.format.should == 'PNG'
        profile_photo.image.columns.should == 96
        profile_photo.image.rows.should == 96
    end

    it 'should accept a draft PNG and not resize it' do
        data = load_file_fixture("parrot.png")
        profile_photo = ProfilePhoto.new(:data => data, :draft => true)
        profile_photo.valid?.should == true
        profile_photo.image.format.should == 'PNG'
        profile_photo.image.columns.should == 198
        profile_photo.image.rows.should == 289
    end


end


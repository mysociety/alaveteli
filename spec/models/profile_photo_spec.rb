# == Schema Information
# Schema version: 20220210114052
#
# Table name: profile_photos
#
#  id         :integer          not null, primary key
#  data       :binary           not null
#  user_id    :integer
#  draft      :boolean          default(FALSE), not null
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

RSpec.describe ProfilePhoto, "when constructing a new photo" do

  before do
    @mock_user = mock_model(User)
  end

  it 'should take no image as invalid' do
    profile_photo = ProfilePhoto.new(:data => nil, :user => @mock_user)
    expect(profile_photo.valid?).to eq(false)
  end

  it 'should take bad binary data as invalid' do
    profile_photo = ProfilePhoto.new(:data => 'blahblahblah', :user => @mock_user)
    expect(profile_photo.valid?).to eq(false)
  end

  it 'should translate a no image error message' do
    AlaveteliLocalization.with_locale(:es) do
      profile_photo = ProfilePhoto.new(:data => nil, :user => @mock_user)
      expect(profile_photo.valid?).to eq(false)
      expect(profile_photo.errors[:data]).to eq(['Por favor elige el fichero que contiene tu foto'])
    end
  end

  it 'should accept and convert a PNG to right size' do
    data = load_file_fixture("parrot.png")
    profile_photo = ProfilePhoto.new(:data => data, :user => @mock_user)
    expect(profile_photo.valid?).to eq(true)
    expect(profile_photo.image.type).to eq('PNG')
    expect(profile_photo.image.width).to eq(96)
    expect(profile_photo.image.height).to eq(96)
  end

  it 'should accept and convert a JPEG to right format and size' do
    data = load_file_fixture("parrot.jpg")
    profile_photo = ProfilePhoto.new(:data => data, :user => @mock_user)
    expect(profile_photo.valid?).to eq(true)
    expect(profile_photo.image.type).to eq('PNG')
    expect(profile_photo.image.width).to eq(96)
    expect(profile_photo.image.height).to eq(96)
  end

  it 'should accept a draft PNG and not resize it' do
    data = load_file_fixture("parrot.png")
    profile_photo = ProfilePhoto.new(:data => data, :draft => true)
    expect(profile_photo.valid?).to eq(true)
    expect(profile_photo.image.type).to eq('PNG')
    expect(profile_photo.image.width).to eq(198)
    expect(profile_photo.image.height).to eq(289)
  end


end

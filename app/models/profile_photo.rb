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

# models/profile_photo.rb:
# Image of user that goes on their profile.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class ProfilePhoto < ApplicationRecord
  # deliberately don't strip_attributes, so keeps raw photo properly

  WIDTH = 96
  HEIGHT = 96
  MAX_DRAFT = 500 # keep even pre-cropped images reasonably small

  belongs_to :user,
             :inverse_of => :profile_photo

  validate :data_and_draft_checks

  attr_accessor :x, :y, :w, :h
  attr_accessor :image

  after_initialize :convert_data_to_image

  # make image valid format and size
  def convert_image
    return if data.nil?
    return if image.nil?

    # convert to PNG if it isn't, and to right size
    altered = false
    if image.type != 'PNG'
      self.image.format('PNG')
      altered = true
    end

    # draft images are before the user has cropped them
    if !draft && (image.width != WIDTH || image.height != HEIGHT)
      # do any exact cropping (taken from Jcrop interface)
      if w && h
        image.crop("#{ w }x#{ h }+#{ x }+#{ y }")
      end
      # do any further cropping
      # resize_to_fill!
      image.combine_options do |c|
        c.thumbnail("#{ WIDTH }x#{ HEIGHT }^")
        c.gravity 'center'
        c.extent("#{ WIDTH }x#{ HEIGHT }")
      end

      altered = true
    end

    if draft && (image.width > MAX_DRAFT || image.height > MAX_DRAFT)
      # resize_to_fit!
      image.resize("#{ MAX_DRAFT }x#{ MAX_DRAFT }")
      altered = true
    end

    if altered
      self.data = image.to_blob
    end
  end

  private

  def data_and_draft_checks
    if data.nil?
      errors.add(:data, _("Please choose a file containing your photo."))
      return
    end

    if image.nil?
      errors.add(:data, _("Couldn't understand the image file that you uploaded. PNG, JPEG, GIF and many other common image file formats are supported."))
      return
    end

    if image.type != 'PNG'
      errors.add(:data, _("Failed to convert image to a PNG"))
    end

    if !draft && (image.width != WIDTH || image.height != HEIGHT)
      errors.add(:data, _("Failed to convert image to the correct size: at {{cols}}x{{rows}}, need {{width}}x{{height}}",
                          :cols => image.width,
                          :rows => image.height,
                          :width => WIDTH,
                          :height => HEIGHT))
    end

    if draft && user_id
      raise "Internal error, draft pictures must not have a user"
    end

    if !draft && !user_id
      raise "Internal error, real pictures must have a user"
    end
  end

  # Convert binary data blob into ImageMagick image when assigned
  def convert_data_to_image
    if data.nil?
      self.image = nil
      return
    end

    begin
      converted = MiniMagick::Image.read(data)
    rescue MiniMagick::Invalid
      self.image = nil
      return
    end

    # TODO: perhaps take largest image or somesuch if there were multiple
    # in the file?
    self.image = converted
    convert_image
  end
end

# == Schema Information
# Schema version: 108
#
# Table name: profile_photos
#
#  id      :integer         not null, primary key
#  data    :binary          not null
#  user_id :integer
#  draft   :boolean         default(FALSE), not null
#

# models/profile_photo.rb:
# Image of user that goes on their profile.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: profile_photo.rb,v 1.2 2009-09-17 21:10:05 francis Exp $
#
require 'mahoro'
require 'RMagick'

class ProfilePhoto < ActiveRecord::Base
    WIDTH = 96
    HEIGHT = 96

    MAX_DRAFT = 500 # keep even pre-cropped images reasonably small

    belongs_to :user

    # deliberately don't strip_attributes, so keeps raw photo properly
    
    attr_accessor :x, :y, :w, :h
    
    # convert binary data blob into ImageMagick image when assigned
    attr_accessor :image
    def after_initialize
        if data.nil?
            self.image = nil
            return
        end

        image_list = Magick::ImageList.new
        begin
            image_list.from_blob(data)
        rescue Magick::ImageMagickError
            self.image = nil
            return
        end
    
        self.image = image_list[0] # XXX perhaps take largest image or somesuch if there were multiple in the file?
        self.convert_image
    end

    # make image valid format and size
    def convert_image
        if self.data.nil?
            return
        end
        if self.image.nil?
            return
        end

        # convert to PNG if it isn't, and to right size
        altered = false
        if self.image.format != 'PNG'
            self.image.format = 'PNG'
            altered = true
        end
        # draft images are before the user has cropped them
        if !self.draft && (image.columns != WIDTH || image.rows != HEIGHT)
            # do any exact cropping (taken from Jcrop interface)
            if self.w && self.h 
                image.crop!(self.x.to_i, self.y.to_i, self.w.to_i, self.h.to_i)
            end
            # do any further cropping
            image.resize_to_fill!(WIDTH, HEIGHT)
            altered = true
        end
        if self.draft && (image.columns > MAX_DRAFT || image.rows > MAX_DRAFT)
            image.resize_to_fit!(MAX_DRAFT, MAX_DRAFT)
            altered = true
        end
        if altered
            write_attribute(:data, self.image.to_blob)
        end
    end

    def validate
        if self.data.nil?
            errors.add(:data, N_("Please choose a file containing your photo."))
            return
        end

        if self.image.nil?
            errors.add(:data, N_("Couldn't understand the image file that you uploaded. PNG, JPEG, GIF and many other common image file formats are supported."))
            return
        end

        if self.image.format != 'PNG'
            errors.add(:data, N_("Failed to convert image to a PNG"))
        end
        
        if !self.draft && (self.image.columns != WIDTH || self.image.rows != HEIGHT)
            errors.add(:data, N_("Failed to convert image to the correct size: at %{cols}x%{rows}, need %{width}x%{height}" % { :cols => self.image.columns, :rows => self.image.rows, :width => WIDTH, :height => HEIGHT }))
        end

        if self.draft && self.user_id
            raise "Internal error, draft pictures must not have a user"
        end

        if !self.draft && !self.user_id
            raise "Internal error, real pictures must have a user"
        end
    end
end



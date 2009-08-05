# models/profile_photo.rb:
# Image of user that goes on their profile.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: profile_photo.rb,v 1.1 2009-08-05 16:31:11 francis Exp $
#
require 'mahoro'
require 'RMagick'

class ProfilePhoto < ActiveRecord::Base
    WIDTH = 96
    HEIGHT = 96

    has_one :user
    validates_presence_of :user

    # deliberately don't strip_attributes, so keeps raw photo properly
    
    # convert binary data blob into ImageMagick image when assigned
    attr_accessor :image
    def data=(data)
        write_attribute(:data, data)
        if data.nil?
            self.image = nil
            return
        end

        image_list = Magick::ImageList.new
        begin
            image_list.from_blob(data)
        rescue Magick::ImageMagickError
            self.image = nil
            write_attribute(:data, nil)
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
        if image.columns != WIDTH || image.rows != HEIGHT
            image.resize_to_fill!(WIDTH, HEIGHT)
            altered = true
        end
        if altered
            write_attribute(:data, self.image.to_blob)
        end
    end

    def validate
        if self.data.nil?
            errors.add(:data, "^No image specified")
            return
        end

        if self.image.nil?
            errors.add(:data, "^Couldn't read the image that you uploaded, please try again.")
            return
        end

        if self.image.format != 'PNG'
            errors.add(:data, "^Failed to convert image to a PNG")
        end
        
        if self.image.columns != WIDTH || self.image.rows != HEIGHT
            errors.add(:data, "^Failed to convert image to the correct size: at #{self.image.columns}x#{self.image.rows}, need #{WIDTH}x#{HEIGHT}")
        end
    end
end



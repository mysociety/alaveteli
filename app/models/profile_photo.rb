# == Schema Information
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
  ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/heic].freeze

  belongs_to :user,
             inverse_of: :profile_photo,
             optional: true

  validate :data_and_draft_checks

  attr_accessor :x, :y, :w, :h

  before_validation :process_data, if: :allowed_content_type?

  def image
    @image ||= MiniMagick::Image.read(data) if allowed_content_type?
  end

  private

  def process_data
    tempfile = Tempfile.new(['profile_photo', '.img'])
    tempfile.binmode
    tempfile.write(data)
    tempfile.rewind

    pipeline = ImageProcessing::MiniMagick.source(tempfile).convert('png')

    if draft
      pipeline = pipeline.resize_to_limit(MAX_DRAFT, MAX_DRAFT)
    else
      pipeline = pipeline.crop(x.to_i, y.to_i, w.to_i, h.to_i) if w && h
      pipeline = pipeline.resize_to_fill(WIDTH, HEIGHT)
    end

    result = pipeline.call
    self.data = result.read
    @image = MiniMagick::Image.read(data)
  rescue StandardError
    @processing_failed = true
  ensure
    tempfile&.close!
    result&.close! if result.respond_to?(:close!)
  end

  def data_and_draft_checks
    if data.nil?
      errors.add(:data, _("Please choose a file containing your photo."))
      return
    end

    unless allowed_content_type?
      errors.add(:data, _("We weren't able to identify the file type of your " \
                          "photo. Please upload a PNG, JPEG, GIF or HEIC " \
                          "image."))
      return
    end

    if @processing_failed
      errors.add(:data, _("Couldn't understand the image file that you " \
                          "uploaded. PNG, JPEG, GIF and HEIC file formats " \
                          "are supported."))
      return
    end

    if draft && user_id
      raise "Internal error, draft pictures must not have a user"
    end

    raise "Internal error, real pictures must have a user" if !draft && !user_id
  end

  def allowed_content_type?
    return false unless data

    ALLOWED_CONTENT_TYPES.include?(AlaveteliFileTypes.content_to_mimetype(data))
  end
end

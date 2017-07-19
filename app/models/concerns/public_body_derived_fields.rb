# -*- encoding : utf-8 -*-
module PublicBodyDerivedFields

  extend ActiveSupport::Concern

  included do
    before_save :set_first_letter

    # When name or short name is changed, also change the url name
    def short_name=(value)
      write_attribute(:short_name, value)
      update_url_name
    end

    def name=(value)
      write_attribute(:name, value)
      update_url_name
    end

  end

  # Return the short name if present, or else long name
  def short_or_long_name
    if short_name.nil? || short_name.empty?
      name.nil? ? "" : name
    else
      short_name
    end
  end

  # Set the first letter, which is used for faster queries
  def set_first_letter
    unless name.blank?
      # we use a regex to ensure it works with utf-8/multi-byte
      new_first_letter = Unicode.upcase name.scan(/^./mu)[0]
      if new_first_letter != first_letter
        self.first_letter = new_first_letter
      end
    end
  end

  def update_url_name
    if changed.include?('name') || changed.include?('short_name')
      self.url_name = MySociety::Format.
                        simplify_url_part(short_or_long_name, 'body')
    end
  end

end

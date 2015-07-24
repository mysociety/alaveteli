module PublicBodyDerivedFields

  extend ActiveSupport::Concern

  included do
    before_save :set_first_letter

    # When name or short name is changed, also change the url name
    def short_name=(short_name)
      super
      update_url_name
    end

    def name=(name)
      super
      update_url_name
    end

  end

  # Return the short name if present, or else long name
  def short_or_long_name
    if self.short_name.nil? || self.short_name.empty?
      self.name.nil? ? "" : self.name
    else
      self.short_name
    end
  end

  # Set the first letter, which is used for faster queries
  def set_first_letter
    unless name.blank?
      # we use a regex to ensure it works with utf-8/multi-byte
      first_letter = Unicode.upcase name.scan(/^./mu)[0]
      if first_letter != self.first_letter
        self.first_letter = first_letter
      end
    end
  end

  def update_url_name
    if changed.include?('name') || changed.include?('short_name')
      self.url_name = MySociety::Format.simplify_url_part(self.short_or_long_name, 'body')
    end
  end

end

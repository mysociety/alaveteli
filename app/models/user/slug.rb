##
# Module to configure Friendly ID slugs for the User model
#
module User::Slug
  extend ActiveSupport::Concern

  included do
    extend FriendlyId

    friendly_id do |config|
      config.base = :name
      config.use :slugged
      config.use :sequentially_slugged

      config.slug_column = :url_name
      config.sequence_separator = '_'
      config.slug_limit = 32
    end

    def should_generate_new_friendly_id?
      return true unless url_name
      !url_name_changed? && name_changed? && active?
    end

    def normalize_friendly_id(_value)
      value = read_attribute(:name)
      return super('user') if value =~ /^[\d_\.]+$/
      super(value).gsub('-', '_')
    end

    def to_param
      id
    end
  end
end

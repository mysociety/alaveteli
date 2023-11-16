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
      config.use :history

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

    # These private methods reverts from the `history` modules implementation
    # to the `slugged` version. This is so generating and searching for slugs
    # works correctly as current slugs need to be migrated to `FriendlyId::Slug`
    # instances.
    private

    # rubocop:disable all
    def slug_base_class
      self.class.base_class
    end

    def slug_column
      friendly_id_config.slug_column
    end

    def scope_for_slug_generator
      scope = self.class.base_class.unscoped
      scope = scope.friendly unless scope.respond_to?(:exists_by_friendly_id?)
      primary_key_name = self.class.primary_key
      scope.where(self.class.base_class.arel_table[primary_key_name].not_eq(send(primary_key_name)))
    end
    # rubocop:enable all
  end
end

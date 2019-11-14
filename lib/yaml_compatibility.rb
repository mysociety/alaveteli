##
# Class to load YAML which includes legacy marshalled Ruby objects.
#
class YAMLCompatibility
  def self.load(yaml, aliases: false, filename: nil, fallback: nil,
                symbolize_names: false)
    result = if Gem::Version.new(YAML::VERSION) >= Gem::Version.new('3.1.0')
               YAML.parse(yaml, filename: filename)
             else
               YAML.parse(yaml, filename)
             end
    return fallback unless result

    result = visitor.accept(result)
    symbolize_names!(result) if symbolize_names
    result
  end

  def self.visitor
    class_loader = LegacyMapClassLoader.new
    scanner = YAML::ScalarScanner.new(class_loader)
    YAML::Visitors::ToRuby.new(scanner, class_loader)
  end

  # :nodoc:
  class LazyAttributeHash < if rails_upgrade?
                              ActiveModel::LazyAttributeHash
                            else
                              ActiveRecord::LazyAttributeHash
                            end
    def key?(key)
      delegate_hash.key?(key) ||
        (values && values.key?(key)) ||
        (types && types.key?(key))
    end
  end

  # :nodoc:
  class TimeZoneConverter
    def init_with(_coder); end
  end

  # :nodoc:
  LegacyObject = Class.new

  # :nodoc:
  class LegacyMapClassLoader < YAML::ClassLoader
    private

    MAPPINGS = {
      'ActiveModel::LazyAttributeHash' =>
        'YAMLCompatibility::LazyAttributeHash',
      'ActiveRecord::LazyAttributeHash' =>
        'YAMLCompatibility::LazyAttributeHash',

      # Rails <5
      'ActiveRecord::AttributeMethods::TimeZoneConversion::TimeZoneConverter' =>
        'YAMLCompatibility::TimeZoneConverter',
      'ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer' =>
        'ActiveModel::Type::Integer',

      # Rails 5.0
      'ActiveModel::Type::Text' =>
        'ActiveRecord::Type::Text',

      # Legacy classes
      'PublicBodyTag' =>
        'YAMLCompatibility::LegacyObject',

      'TMail::AddressHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::Config' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::ContentDispositionHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::ContentTransferEncodingHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::ContentTypeHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::DateTimeHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::Mail' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::MessageIdHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::MimeVersionHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::ReceivedHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::ReferencesHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::ReturnPathHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::SingleAddressHeader' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::StringPort' =>
        'YAMLCompatibility::LegacyObject',
      'TMail::UnstructuredHeader' =>
        'YAMLCompatibility::LegacyObject'
    }

    def resolve(klassname)
      super(MAPPINGS[klassname] || klassname)
    end
  end
end

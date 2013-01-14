# Some of the monkeypatches in this file should possibly be submitted
# as patches, but most are here because they should go away when we
# upgrade to Rails 3.x

# override behaviour in fast_gettext/translation.rb
# so that we can interpolate our translation strings nicely

def _(key, options = {})
  translation = FastGettext._(key) || key
  gettext_interpolate(translation, options)
end

INTERPOLATION_RESERVED_KEYS = %w(scope default)
MATCH = /(\\\\)?\{\{([^\}]+)\}\}/

def gettext_interpolate(string, values)
  return string unless string.is_a?(String)
  if values.is_a?(Hash)
    string.gsub(MATCH) do
      escaped, pattern, key = $1, $2, $2.to_sym
      
      if escaped
        pattern
      elsif INTERPOLATION_RESERVED_KEYS.include?(pattern)
        raise I18n::ReservedInterpolationKey.new(pattern, string)
      elsif !values.include?(key)
        raise I18n::MissingInterpolationArgument.new(pattern, string)
      else
        values[key].to_s
      end
    end
  else
    reserved_keys = if defined?(I18n::RESERVED_KEYS) # rails 3+
                      I18n::RESERVED_KEYS
                    else
                      I18n::Backend::Base::RESERVED_KEYS
                    end

    string % values.except(*reserved_keys)
  end
end


module I18n
  # used by Globalize plugin.  
  # XXX much of this stuff should (might?) be in newer versions of Rails
  @@fallbacks = nil
  class << self
    # Returns the current fallbacks implementation. Defaults to +I18n::Locale::Fallbacks+.
    def fallbacks
      @@fallbacks ||= I18n::Locale::Fallbacks.new
    end
  end

  module Locale
    module Tag
      class Simple
        class << self
          def tag(tag)
            new(tag)
          end
        end

        attr_reader :tag

        def initialize(*tag)
          @tag = tag.join('-').to_sym
        end

        def subtags
          @subtags = tag.to_s.split('-').map { |subtag| subtag.to_s }
        end

        def to_sym
          tag
        end

        def to_s
          tag.to_s
        end

        def to_a
          subtags
        end

        def parent
          @parent ||= begin
            segs = to_a.compact
            segs.length > 1 ? self.class.tag(*segs[0..(segs.length-2)].join('-')) : nil
          end
        end

        def self_and_parents
          @self_and_parents ||= [self] + parents
        end

        def parents
          @parents ||= ([parent] + (parent ? parent.parents : [])).compact
        end


      end
    end
    class Fallbacks < Hash
      def initialize(*mappings)
        @map = {}
        map(mappings.pop) if mappings.last.is_a?(Hash)
        self.defaults = mappings.empty? ? [I18n.default_locale.to_sym] : mappings
      end

      def defaults=(defaults)
        @defaults = defaults.map { |default| compute(default, false) }.flatten
      end
      attr_reader :defaults
      
      def [](locale)
        raise InvalidLocale.new(locale) if locale.nil?
        locale = locale.to_sym
        super || store(locale, compute(locale))
      end

      def map(mappings)
        mappings.each do |from, to|
          from, to = from.to_sym, Array(to)
          to.each do |_to|
            @map[from] ||= []
            @map[from] << _to.to_sym
          end
        end
      end

      protected
    
      def compute(tags, include_defaults = true)
        result = Array(tags).collect do |tag|
          tags = I18n::Locale::Tag::Simple.tag(tag).self_and_parents.map! { |t| t.to_sym }
          tags.each { |_tag| tags += compute(@map[_tag]) if @map[_tag] }
          tags
        end.flatten
        result.push(*defaults) if include_defaults
        result.uniq.compact
      end
    end
    autoload :Fallbacks, 'i18n/locale/fallbacks'
  end
end


# this monkeypatch corrects inconsistency with gettext_i18n_rails
# where the latter deals with strings but rails i18n deals with
# symbols for locales
module GettextI18nRails
  class Backend
      def available_locales
          FastGettext.available_locales.map{|l| l.to_sym} || []
      end 
  end
end


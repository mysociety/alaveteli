# -*- encoding : utf-8 -*-
# override behaviour in fast_gettext/translation.rb
# so that we can interpolate our translation strings nicely

# TODO: We could simplify a lot of this code (as in remove it) if we moved from using the {{value}}
# convention in the translation strings for interpolation to %{value}. This is apparently the newer
# convention.

def _(key, options = {})
  translation = (FastGettext._(key) || key).html_safe
  gettext_interpolate(translation, options)
end

def n_(*keys)
  # The last parameter should be the values to do the interpolation with
  if keys.count > 3
    options = keys.pop
  else
    options = {}
  end
  translation = FastGettext.n_(*keys).html_safe
  gettext_interpolate(translation, options)
end

MATCH = /\{\{([^\}]+)\}\}/

def gettext_interpolate(string, values)
  return string unless string.is_a?(String)
  # $1, $2 don't work with SafeBuffer so casting to string as workaround
  safe = string.html_safe?
  string = string.to_str.gsub(MATCH) do
    pattern, key = $1, $1.to_sym

    if !values.include?(key)
      raise I18n::MissingInterpolationArgument.new(pattern, string, values)
    else
      v = values[key].to_s
      if safe && !v.html_safe?
        ERB::Util.h(v)
      else
        v
      end
    end
  end
  safe ? string.html_safe : string
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

# Monkeypatch Globalize to compensate for the way gettext_i18n_rails patches
# I18n.locale= so that it changes underscores in locale names (as used in the gettext world)
# to the dashes that I18n prefers
module Globalize
  class << self
    def locale
      read_locale || I18n.locale.to_s.gsub('-', '_').to_sym
    end
  end
end

# Backported fix from Rails 4.1 to fix an error when 'en' is not in available
# locales and an ActiveSupport::Duration method is called (e.g. `21.days`)
# otherwise 4.0 attempts to call `to_sentence` with (`:locale => :en`) which
# raises `I18n::InvalidLocale: :en is not a valid locale`
module ActiveSupport
  class Duration
    def inspect #:nodoc:
      parts.
        reduce(::Hash.new(0)) { |h,(l,r)| h[l] += r; h }.
        sort_by {|unit,  _ | [:years, :months, :days, :minutes, :seconds].index(unit)}.
        map     {|unit, val| "#{val} #{val == 1 ? unit.to_s.chop : unit.to_s}"}.
        to_sentence(locale: ::I18n.default_locale)
    end
  end
end

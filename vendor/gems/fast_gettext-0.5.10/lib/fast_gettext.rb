require 'fast_gettext/mo_file'
require 'fast_gettext/storage'
require 'fast_gettext/translation'
require 'fast_gettext/translation_repository'
require 'fast_gettext/vendor/string'

module FastGettext
  include FastGettext::Storage
  extend self

  VERSION = File.read( File.join(File.dirname(__FILE__), 'fast_gettext', 'VERSION') ).strip
  LOCALE_REX =  /^[a-z]{2}$|^[a-z]{2}_[A-Z]{2}$/
  NAMESPACE_SEPERATOR = '|'

  # users should not include FastGettext, since this would conterminate their namespace
  # rather use
  # FastGettext.locale = ..
  # FastGettext.text_domain = ..
  # and
  # include FastGettext::Translation
  FastGettext::Translation.public_instance_methods.each do |method|
    define_method method do |*args|
      Translation.send(method,*args)
    end
  end

  def add_text_domain(name,options)
    translation_repositories[name] = TranslationRepository.build(name,options)
  end
end

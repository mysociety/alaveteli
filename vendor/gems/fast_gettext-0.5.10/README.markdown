FastGettext
===========
GetText but 3.5 x faster, 560 x less memory, simple, clean namespace (7 vs 34) and threadsave!  

It supports multiple backends (.mo, .po, .yml files, Database(ActiveRecor + any other), Chain, Loggers) and can easily be extended.

[Example Rails application](https://github.com/grosser/gettext_i18n_rails_example)

Comparison
==========
<table>
  <tr>
    <td></td>
    <td width="100">Hash</td>
    <td width="150">FastGettext</td>
    <td width="100">GetText</td>
    <td width="100">ActiveSupport I18n::Simple</td>
  </tr>
  <tr>
    <td>Speed*</td>
    <td>0.82s</td>
    <td>1.36s</td>
    <td>4.88s</td>
    <td>21.77s</td>
  </tr>
  <tr>
    <td>RAM*</td>
    <td>4K</td>
    <td>8K</td>
    <td>4480K</td>
    <td>10100K</td>
  </tr>
  <tr>
    <td>Included backends</td>
    <td></td>
    <td>db, yml, mo, po, logger, chain</td>
    <td>mo</td>
    <td>yml</td>
  </tr>
</table>
<small>*50.000 translations with ruby enterprise 1.8.6 through `rake benchmark`</small>

Setup
=====
### 1. Install
    sudo gem install fast_gettext

### 2. Add a translation repository

From mo files (traditional/default)
    FastGettext.add_text_domain('my_app',:path=>'locale')

Or po files (less maintenance than mo)
    FastGettext.add_text_domain('my_app',:path=>'locale', :type=>:po)
    # :ignore_fuzzy => true to silence warnings about fuzzy translations
    # :ignore_obsolete => true to silence warnings about obsolete translations

Or yaml files (use I18n syntax/indentation)
    FastGettext.add_text_domain('my_app',:path=>'config/locales', :type=>:yaml)

Or database (scaleable, good for many locales/translators)
    # db access is cached <-> only first lookup hits the db 
    require "fast_gettext/translation_repository/db"
    FastGettext::TranslationRepository::Db.require_models #load and include default models
    FastGettext.add_text_domain('my_app', :type=>:db, :model=>TranslationKey)

### 3. Choose text domain and locale for translation
Do this once in every Thread. (e.g. Rails -> ApplicationController)
    FastGettext.text_domain = 'my_app'
    FastGettext.available_locales = ['de','en','fr','en_US','en_UK'] # only allow these locales to be set (optional)
    FastGettext.locale = 'de'

### 4. Start translating
    include FastGettext::Translation
    _('Car') == 'Auto'
    _('not-found') == 'not-found'
    s_('Namespace|no-found') == 'not-found'
    n_('Axis','Axis',3) == 'Achsen' #German plural of Axis


Managing translations
============
### mo/po-files
Generate .po or .mo files using GetText parser (example tasks at [gettext_i18n_rails](http://github.com/grosser/gettext_i18n_rails))

Tell Gettext where your .mo or .po files lie, e.g. for locale/de/my_app.po and locale/de/LC_MESSAGES/my_app.mo
    FastGettext.add_text_domain('my_app',:path=>'locale')

Use the [original GetText](http://github.com/mutoh/gettext) to create and manage po/mo-files.
(Work on a po/mo parser & reader that is easier to use has started, contributions welcome @ [pomo](http://github.com/grosser/pomo) )

###Database
[Example migration for ActiveRecord](http://github.com/grosser/fast_gettext/blob/master/examples/db/migration.rb)  
The default plural seperator is `||||` but you may overwrite it (or suggest a better one..).

This is usable with any model DataMapper/Sequel or any other(non-database) backend, the only thing you need to do is respond to the self.translation(key, locale) call.
If you want to use your own models, have a look at the [default models](http://github.com/grosser/fast_gettext/tree/master/lib/fast_gettext/translation_repository/db_models) to see what you want/need to implement.

To manage translations via a Web GUI, use a [Rails application and the translation_db_engine](http://github.com/grosser/translation_db_engine)

Rails
=======================
Try the [gettext_i18n_rails plugin](http://github.com/grosser/gettext_i18n_rails), it simplifies the setup.  
Try the [translation_db_engine](http://github.com/grosser/translation_db_engine), to manage your translations in a db.

Setting `available_locales`,`text_domain` or `locale` will not work inside the `evironment.rb`,
since it runs in a different thread then e.g. controllers, so set them inside your application_controller.

    #environment.rb after initializers
    Object.send(:include,FastGettext::Translation)
    FastGettext.add_text_domain('accounting',:path=>'locale')
    FastGettext.add_text_domain('frontend',:path=>'locale')
    ...

    #application_controller.rb
    class ApplicationController ...
      include FastGettext::Translation
      before_filter :set_locale
      def set_locale
        FastGettext.available_locales = ['de','en',...]
        FastGettext.text_domain = 'frontend'
        session[:locale] = I18n.locale = FastGettext.set_locale(params[:locale] || session[:locale] || request.env['HTTP_ACCEPT_LANGUAGE'] || 'en')
      end


Advanced features
=================
###Abnormal pluralisation
Pluralisation rules can be set directly via a lambda (see specs/), or by using the Gettext
plural definition (see spec/locale/en/test_plural.po or [Plural expressions for all languages](http://translate.sourceforge.net/wiki/l10n/pluralforms).


###default_text_domain
If you only use one text domain, setting `FastGettext.default_text_domain = 'app'`
is sufficient and no more `text_domain=` is needed

###default_locale
If the simple rule of "first `availble_locale` or 'en'" is not suficcient for you, set `FastGettext.default_locale = 'de'`.

###default_available_locales
Fallback when no available_locales are set

###Chains
You can use any number of repositories to find a translation. Simply add them to a chain and when
the first cannot translate a given key, the next is asked and so forth.
    repos = [
      FastGettext::TranslationRepository.build('new', :path=>'....'),
      FastGettext::TranslationRepository.build('old', :path=>'....')
    ]
    FastGettext.add_text_domain 'combined', :type=>:chain, :chain=>repos

###Logger
When you want to know which keys could not be translated or were used, add a Logger to a Chain:
    repos = [
      FastGettext::TranslationRepository.build('app', :path=>'....')
      FastGettext::TranslationRepository.build('logger', :type=>:logger, :callback=>lamda{|key_or_array_of_ids| ... }),
    }
    FastGettext.add_text_domain 'combined', :type=>:chain, :chain=>repos
If the Logger is in position #1 it will see all translations, if it is in position #2 it will only see the unfound.
Unfound may not always mean missing, if you chose not to translate a word because the key is a good translation, it will appear nevertheless.
A lambda or anything that responds to `call` will do as callback. A good starting point may be `examples/missing_translations_logger.rb`.

###Plugins
Want a xml version ?
Write your own TranslationRepository!
    #fast_gettext/translation_repository/xxx.rb
    module FastGettext
      module TranslationRepository
        class Wtf
          define initialize(name,options), [key], plural(*keys) and
          either inherit from TranslationRepository::Base or define available_locales and pluralisation_rule
        end
      end
    end


FAQ
===
 - [Problems with ActiveRecord messages?](http://wiki.github.com/grosser/fast_gettext/activerecord)


TODO
====
 - YML backend that reads ActiveSupport::I18n files
 - any ideas ? :D

Author
======
Mo/Po-file parsing from Masao Mutoh, see vendor/README

###Contributors
 - [geekq](http://www.innoq.com/blog/vd)
 - [Matt Sanford](http://blog.mzsanford.com)
 - [Antonio Terceiro](http://softwarelivre.org/terceiro)
 - [J. Pablo Fernández](http://pupeno.com)
 - Rudolf Gavlas

[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...  

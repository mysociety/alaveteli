[FastGettext](http://github.com/grosser/fast_gettext) / Rails integration.

Translate via FastGettext, use any other I18n backend as extension/fallback.

Rails does: `I18n.t('syntax.with.lots.of.dots')` with nested yml files
We do: `_('Just translate my damn text!')` with simple, flat mo/po/yml files or directly from db
To use I18n calls add a `syntax.with.lots.of.dots` translation.

[See it working in the example application.](https://github.com/grosser/gettext_i18n_rails_example)

Setup
=====
### Installation

#### Rails 3

##### As plugin:

    rails plugin install git://github.com/grosser/gettext_i18n_rails.git

    # Gemfile
    gem 'fast_gettext', '>=0.4.8'

##### As gem:

    # Gemfile
    gem 'gettext_i18n_rails'

##### Optional:
If you want to find translations or build .mo files
    # Gemfile
    gem 'gettext', '>=1.9.3', :require => false, :group => :development

#### Rails 2

##### As plugin:

    script/plugin install git://github.com/grosser/gettext_i18n_rails.git
    sudo gem install fast_gettext

    # config/environment.rb
    config.gem "fast_gettext", :version => '>=0.4.8'

##### As gem:

    gem install gettext_i18n_rails

    # config/environment.rb
    config.gem 'gettext_i18n_rails'

    #Rakefile
    begin
      require "gettext_i18n_rails/tasks"
    rescue LoadError
      puts "gettext_i18n_rails is not installed, you probably should run 'rake gems:install' or 'bundle install'."
    end

##### Optional:
If you want to find translations or build .mo files
    # config/environments/development.rb
    config.gem "gettext", :version => '>=1.9.3', :lib => false

### Locales & initialisation
Copy default locales with dates/sentence-connectors/AR-errors you want from e.g.
[rails i18n](http://github.com/svenfuchs/rails-i18n/tree/master/rails/locale/) into 'config/locales'

To initialize:

    # config/initializers/fast_gettext.rb
    FastGettext.add_text_domain 'app', :path => 'locale', :type => :po
    FastGettext.default_available_locales = ['en','de'] #all you want to allow
    FastGettext.default_text_domain = 'app'

And in your application:

    # app/controllers/application_controller.rb
    class ApplicationController < ...
      before_filter :set_gettext_locale

Translating
===========
Performance is almost the same for all backends since translations are cached after first use.

### Option A: .po files

    FastGettext.add_text_domain 'app', :path => 'locale', :type => :po

 - use some _('translations')
 - run `rake gettext:find`, to let GetText find all translations used
 - (optional) run `rake gettext:store_model_attributes`, to parse the database for columns that can be translated
 - if this is your first translation: `cp locale/app.pot locale/de/app.po` for every locale you want to use
 - translate messages in 'locale/de/app.po' (leave msgstr blank and msgstr == msgid)

New translations will be marked "fuzzy", search for this and remove it, so that they will be used.
Obsolete translations are marked with ~#, they usually can be removed since they are no longer needed

#### Unfound translations with rake gettext:find
Dynamic translations like `_("x"+"u")` cannot be fond. You have 4 options:

 - add `N_('xu')` somewhere else in the code, so the parser sees it
 - add `N_('xu')` in a totally separate file like `locale/unfound_translations.rb`, so the parser sees it
 - use the [gettext_test_log rails plugin ](http://github.com/grosser/gettext_test_log) to find all translations that where used while testing
 - add a Logger to a translation Chain, so every unfound translations is logged ([example]((http://github.com/grosser/fast_gettext)))

### Option B: Traditional .po/.mo files

    FastGettext.add_text_domain 'app', :path => 'locale'

 - follow Option A
 - run `rake gettext:pack` to write binary GetText .mo files

### Option C: Database
Most scalable method, all translators can work simultaneously and online.

Easiest to use with the [translation database Rails engine](http://github.com/grosser/translation_db_engine).
Translations can be edited under `/translation_keys`

    FastGettext::TranslationRepository::Db.require_models
    FastGettext.add_text_domain 'app', :type => :db, :model => TranslationKey

I18n
====
    I18n.locale <==> FastGettext.locale.to_sym
    I18n.locale = :de <==> FastGettext.locale = 'de'

Any call to I18n that matches a gettext key will be translated through FastGettext.

Namespaces
==========
Car|Model means Model in namespace Car.
You do not have to translate this into english "Model", if you use the
namespace-aware translation
    s_('Car|Model') == 'Model' #when no translation was found

XSS / html_safe
===============
If you trust your translators and all your usages of % on translations:<br/>
    # config/environment.rb
    GettextI18nRails.translations_are_html_safe = true

String % vs html_safe is buggy (can be used for XSS on 1.8 and is always non-safe in 1.9)<br/>
My recommended fix is: `require 'gettext_i18n_rails/string_interpolate_fix'`

 - safe stays safe (escape added strings)
 - unsafe stays unsafe (do not escape added strings)

ActiveRecord - error messages
=============================
ActiveRecord error messages are translated through Rails::I18n, but
model names and model attributes are translated through FastGettext.
Therefore a validation error on a BigCar's wheels_size needs `_('big car')` and `_('BigCar|Wheels size')`
to display localized.

The model/attribute translations can be found through `rake gettext:store_model_attributes`,
(which ignores some commonly untranslated columns like id,type,xxx_count,...).

Error messages can be translated through FastGettext, if the ':message' is a translation-id or the matching Rails I18n key is translated.

####Option A:
Define a translation for "I need my rating!" and use it as message.
    validates_inclusion_of :rating, :in=>1..5, :message=>N_('I need my rating!')

####Option B:
    validates_inclusion_of :rating, :in=>1..5
Make a translation for the I18n key: `activerecord.errors.models.rating.attributes.rating.inclusion`

####Option C:
Add a translation to each config/locales/*.yml files
    en:
      activerecord:
        errors:
          models:
            rating:
              attributes:
                rating:
                  inclusion: " -- please choose!"
The [rails I18n guide](http://guides.rubyonrails.org/i18n.html) can help with Option B and C.

Plurals
=======
FastGettext supports pluralization
    n_('Apple','Apples',3) == 'Apples'

Abnormal plurals like e.g. Polish that has 4 different can also be addressed, see [FastGettext Readme](http://github.com/grosser/fast_gettext)

Customizing list of translatable files
======================================
When you run

    rake gettext:find

by default the following files are going to be scanned for translations: {app,lib,config,locale}/**/*.{rb,erb,haml}. If
you want to specify a different list, you can redefine files_to_translate in the gettext namespace in a file like
lib/tasks/gettext.rake:

    namespace :gettext do
      def files_to_translate
        Dir.glob("{app,lib,config,locale}/**/*.{rb,erb,haml,rhtml}")
      end
    end

[Contributors](http://github.com/grosser/gettext_i18n_rails/contributors)
======
 - [ruby gettext extractor](http://github.com/retoo/ruby_gettext_extractor/tree/master) from [retoo](http://github.com/retoo)
 - [Paul McMahon](http://github.com/pwim)
 - [Duncan Mac-Vicar P](http://duncan.mac-vicar.com/blog)
 - [Ramihajamalala Hery](http://my.rails-royce.org)
 - [J. Pablo Fernández](http://pupeno.com)
 - [Anh Hai Trinh](http://blog.onideas.ws)
 - [ed0h](http://github.com/ed0h)
 - [Nikos Dimitrakopoulos](http://blog.nikosd.com)

[Michael Grosser](http://grosser.it)<br/>
grosser.michael@gmail.com<br/>
Hereby placed under public domain, do what you want, just do not hold me accountable...

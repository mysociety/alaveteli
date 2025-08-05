# AlaveteliFeatures

This is a small gem for Alaveteli sites which adds a feature flipping library.

## Installation

Add this line to your application's Gemfile:

    gem 'alaveteli_features'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install alaveteli_features

Then run:

    $ rails g alaveteli_features:install

to install the necessary migrations and an example initializer file.

## Usage

Configure your features in `config/initializers/alaveteli_features.rb` with
something like:

    AlaveteliFeatures.backend.enable(:feature_name)

`AlaveteliFeatures.backend` is an instance of [Flipper](https://github.com/jnunemaker/flipper/)
so you can use [any of the DSL methods](https://github.com/jnunemaker/flipper/blob/master/docs/Gates.md)
it provides.

By default, AlaveteliFeatures uses the active record backend, you can also
swap the backend for a different one:

    require 'flipper/adapters/memory'

    memory_backend = Flipper.new(Flipper::Adapters::Memory.new)
    AlaveteliFeatures.backend = memory_backend


To check for enabled features in your backend, use the `feature_enabled?`
helper. This is lazily-included in `ActionController::Base` and
`ActionView::Base` so you can use it in your controllers and views
automatically. To use it elsewhere just include the `Helpers` module in any
class that needs it:

    class SomeClass
      include AlaveteliFeatures::Helpers
    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

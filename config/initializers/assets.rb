# -*- encoding : utf-8 -*-
# Be sure to restart your server when you modify this file.
Rails.application.configure do

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Enable the asset pipeline
  config.assets.enabled = true

  # Change the path that assets are served from
  # config.assets.prefix = "/assets"

  # Add additional assets to the asset load path
  # Rails.application.config.assets.paths << Emoji.images_path

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  # Rails.application.config.assets.precompile += %w( search.js )

  # These additional precompiled asset files are actually
  # manifests that require the real asset files:
  config.assets.precompile += ['admin.js',
                               'profile-photos.js',
                               'stats.js',
                               'fancybox.css',
                               'fancybox.js']
  # ... while these are individual files that can't easily be
  # grouped:
  config.assets.precompile += ['jquery.Jcrop.min.css',
                               'excanvas.min.js',
                               'select-authorities.js',
                               'new-request.js',
                               'time_series.js',
                               'fonts.css',
                               'print.css',
                               'admin.css',
                               'ie6.css',
                               'ie7.css',
                               'bootstrap-dropdown.js',
                               'widget.css',
                               'request-attachments.js',
                               'alaveteli_pro/request-index.js',
                               'responsive/print.css',
                               'responsive/application-lte-ie7.css',
                               'responsive/application-ie8.css']

  config.sass.load_paths += [
    "#{Gem.loaded_specs['foundation-rails'].full_gem_path}/vendor/assets/stylesheets/foundation/components",
    "#{Gem.loaded_specs['foundation-rails'].full_gem_path}/vendor/assets/stylesheets/foundation/"
  ]

end

# -*- encoding : utf-8 -*-
# Set up our available features and (optionally) get some defaults for
# them from the config/general.yml configuration.

# See Flipper's documentation for further examples of how you can enable
# and disable features, noting that (depending on the adapter used) there
# might well be settings stored in other places (the db, caches, etc) that
# you need to respect.
# https://github.com/jnunemaker/flipper/blob/master/lib/flipper/dsl.rb

features = %i[
  annotations
  alaveteli_pro
  projects
  pro_pricing
  pro_self_serve
]

backend = AlaveteliFeatures.backend

features.each do |feature|
  if AlaveteliConfiguration.public_send("enable_#{feature}")
    backend.enable(feature) unless backend.enabled?(feature)
  elsif backend.enabled?(feature)
    backend.disable(feature)
  end
end

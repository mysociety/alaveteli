# -*- encoding : utf-8 -*-
# Set up our available features and (optionally) get some defaults for
# them from the config/general.yml configuration.

# See Flipper's documentation for further examples of how you can enable
# and disable features, noting that (depending on the adapter used) there
# might well be settings stored in other places (the db, caches, etc) that
# you need to respect.
# https://github.com/jnunemaker/flipper/blob/master/lib/flipper/dsl.rb

# Annotations
# We enable annotations globally based on the ENABLE_ANNOTATIONS config
if AlaveteliConfiguration.enable_annotations
  AlaveteliFeatures.backend.enable(:annotations) unless AlaveteliFeatures.backend.enabled?(:annotations)
else
  AlaveteliFeatures.backend.disable(:annotations) unless !AlaveteliFeatures.backend.enabled?(:annotations)
end

# AlaveteliPro
# We enable alaveteli_pro globally based on the ENABLE_ALAVETELI_PRO config
if AlaveteliConfiguration.enable_alaveteli_pro
  AlaveteliFeatures.backend.enable(:alaveteli_pro) unless AlaveteliFeatures.backend.enabled?(:alaveteli_pro)
else
  AlaveteliFeatures.backend.disable(:alaveteli_pro) unless !AlaveteliFeatures.backend.enabled?(:alaveteli_pro)
end

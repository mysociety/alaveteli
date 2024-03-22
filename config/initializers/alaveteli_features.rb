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

Rails.configuration.after_initialize do
  poller = AlaveteliFeatures.features.add(
    :accept_mail_from_poller,
    label: 'Receive response via the POP poller',
    condition: -> {
      AlaveteliConfiguration.production_mailer_retriever_method == 'pop'
    }
  )
  notifications = AlaveteliFeatures.features.add(
    :notifications,
    label: 'Daily email notification digests'
  )
  batch_category = AlaveteliFeatures.features.add(
    :pro_batch_category_ui,
    label: 'Batch category user interface',
    condition: -> {
      PublicBody.category_root.children.any?
    }
  )
  batch_add_all = AlaveteliFeatures.features.add(
    :pro_batch_category_add_all,
    label: 'Batch category "add all" button'
  )

  next unless ActiveRecord::Base.connection.data_source_exists?(:roles)

  base = AlaveteliFeatures.groups.add(
    :base,
    roles: [Role.pro_role],
    features: [poller, notifications, batch_category]
  )

  AlaveteliFeatures.groups.add(
    :beta,
    includes: [base],
    features: [batch_add_all]
  )
end

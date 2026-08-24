Rails::Application.send(:attr_accessor, :admin_importmap)

Rails.application.admin_importmap = Importmap::Map.new.tap do |map|
  importmap_path = Rails.root.join('config/importmaps/admin.rb')
  map.draw(importmap_path) if File.exist?(importmap_path)
end

# importmap-rails only sweeps the map it draws itself, so this one has to
# watch the same paths to notice a changed file
if Rails.application.config.importmap.sweep_cache &&
   !Rails.application.config.cache_classes
  Rails.application.admin_importmap.cache_sweeper(
    watches: Rails.application.config.importmap.cache_sweepers
  )

  ActiveSupport.on_load(:action_controller_base) do
    before_action do
      Rails.application.admin_importmap.cache_sweeper.execute_if_updated
    end
  end
end

Rails::Application.send(:attr_accessor, :admin_importmap)

Rails.application.admin_importmap = Importmap::Map.new.tap do |map|
  importmap_path = Rails.root.join('config/importmaps/admin.rb')
  map.draw(importmap_path) if File.exist?(importmap_path)
end

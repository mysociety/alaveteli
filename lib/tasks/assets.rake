# -*- encoding : utf-8 -*-
namespace :assets do
  desc 'Symlink non-digest asset paths to the most recent digest versions'
  task link_non_digest: :environment do
    assets = Dir.glob(File.join(Rails.root, 'public/assets/**/*'))
    regex = /(-{1}[a-z0-9]{32}*\.{1}){1}/
    assets.each do |file|
      next if File.directory?(file) || file !~ regex

      source = file.split('/')
      source.push(source.pop.gsub(regex, '.'))

      non_digested = File.join(source)
      FileUtils.ln_sf(file, non_digested)
    end
  end
end

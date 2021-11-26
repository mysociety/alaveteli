namespace :storage do
  desc 'Migrate files to ActiveStorage'
  task migrate: :environment do
    Rake::Task['storage:raw_emails:migrate'].execute
  end
end

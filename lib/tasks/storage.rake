namespace :storage do
  desc 'Migrate files to ActiveStorage'
  task migrate: :environment do
    Rake::Task['storage:raw_emails:migrate'].execute
    Rake::Task['storage:attachments:migrate'].execute
  end

  desc 'Mirror files from primary ActiveStorage backend to secondary backends'
  task mirror: :environment do
    Rake::Task['storage:raw_emails:mirror'].execute
    Rake::Task['storage:attachments:mirror'].execute
  end

  desc 'Promote mirrored files to be served from the secondary backend'
  task promote: :environment do
    Rake::Task['storage:raw_emails:promote'].execute
    Rake::Task['storage:attachments:promote'].execute
  end

  desc 'Unlink primary file if mirrored and promoted to secondary backend'
  task unlink: :environment do
    Rake::Task['storage:raw_emails:unlink'].execute
    Rake::Task['storage:attachments:unlink'].execute
  end

  task relocate_to_secondary_backend: :environment do
    Rake::Task['storage:mirror'].execute
    Rake::Task['storage:promote'].execute
    Rake::Task['storage:unlink'].execute
  end
end

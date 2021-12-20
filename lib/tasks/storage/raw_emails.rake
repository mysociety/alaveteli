namespace :storage do
  namespace :raw_emails do
    require_relative 'storage'

    def raw_email_storage
      Storage.new(RawEmail, :file)
    end

    task migrate: :environment do
      raw_email_storage.migrate
    end

    task mirror: :environment do
      raw_email_storage.mirror
    end

    task promote: :environment do
      raw_email_storage.promote
    end

    task unlink: :environment do
      raw_email_storage.unlink
    end
  end
end

namespace :storage do
  namespace :attachments do
    require_relative 'storage'

    def attachment_storage
      Storage.new(
        FoiAttachment, :file,
        setter: :body=,
        getter: :body,
        condition: -> (a) { File.exist?(a.filepath) }
      )
    end

    task migrate: :environment do
      attachment_storage.migrate
    end

    task mirror: :environment do
      attachment_storage.mirror
    end

    task promote: :environment do
      attachment_storage.promote
    end

    task unlink: :environment do
      attachment_storage.unlink
    end
  end
end

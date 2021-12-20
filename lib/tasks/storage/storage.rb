##
# Helper class to:
#   1. migrate file into ActiveStorage
#   2. mirror ActiveStorage blobs between secondary mirrors
#   3. promote ActiveStorage secondary mirrors to serve blobs data
#
# Require a ActiveRecord class and symbol representing the has_one_attached
# association.
#
class Storage
  def initialize(klass, association, setter: :data=, getter: :data)
    @klass = klass
    @association = association
    @setter = setter
    @getter = getter
  end

  def migrate
    count = unattached_files.count
    puts unless count.zero?

    unattached_files.find_each.with_index do |file, index|
      Kernel.silence_warnings do
        file.public_send(@setter, file.public_send(@getter))
      end

      erase_line
      print "#{prefix}: Migrated #{index + 1}/#{count}"
    end

    erase_line
    puts "#{prefix}: Migrated old files storage to #{service_name} completed."
  end

  def mirror
    return puts(not_a_mirror) unless mirrored_service?

    count = mirrored_blobs.count
    puts unless count.zero?

    mirrored_blobs.find_each.with_index do |blob, index|
      mirrored_service.mirror(blob.key, checksum: blob.checksum)

      erase_line
      print "#{prefix}: Mirrored #{index + 1}/#{count}"
    end

    erase_line
    puts "#{prefix}: Mirrored from #{primary.name} to #{secondary.name} " \
         "completed."
  end

  def promote
    return puts(not_a_mirror) unless mirrored_service?

    count = mirrored_blobs.count
    puts unless count.zero?

    mirrored_blobs.find_each.with_index do |blob, index|
      next unless secondary.exist?(blob.key)
      blob.update(service_name: secondary.name)

      erase_line
      print "#{prefix}: Promote #{index + 1}/#{count}"
    end

    erase_line
    puts "#{prefix}: Promoted blobs in #{primary.name} to #{secondary.name} " \
         "completed."
  end

  def unlink
    return puts(not_a_mirror) unless mirrored_service?

    count = secondary_blobs.count
    puts unless count.zero?

    secondary_blobs.find_each.with_index do |blob, index|
      next unless primary.exist?(blob.key)

      primary.delete(blob.key)

      erase_line
      puts "#{prefix}: Unlink #{index + 1}/#{count}"
    end

    erase_line
    puts "#{prefix}: Unlinked files in #{primary.name} completed."
  end

  private

  def unattached_files
    @klass.left_joins(:"#{@association}_attachment").where(
      active_storage_attachments: { id: nil }
    )
  end

  def blobs
    ActiveStorage::Blob.joins(:attachments).where(
      active_storage_attachments: {
        name: @association, record_type: @klass.to_s
      }
    )
  end

  def mirrored_blobs
    blobs.where(service_name: service_name)
  end

  def secondary_blobs
    blobs.where(service_name: secondary.name)
  end

  def attachment
    @klass.reflect_on_attachment(@association)
  end

  def service_name
    attachment.options[:service_name]
  end

  def service
    ActiveStorage::Blob.services.fetch(service_name)
  end

  def mirrored_service?
    service.respond_to?(:mirror)
  end

  def mirrored_service
    raise not_a_mirror unless mirrored_service?
    service
  end

  def not_a_mirror
    "#{prefix}: Not using the mirror service, ensure config/storage.yml is " \
    "correct."
  end

  def primary
    mirrored_service.primary
  end

  def secondary
    mirrored_service.mirrors.first
  end

  def prefix
    @klass.to_s
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1E\e[1A\e[K"
  end
end

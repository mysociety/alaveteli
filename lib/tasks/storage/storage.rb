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

  private

  def unattached_files
    @klass.left_joins(:"#{@association}_attachment").where(
      active_storage_attachments: { id: nil }
    )
  end

  def attachment
    @klass.reflect_on_attachment(@association)
  end

  def service_name
    attachment.options[:service_name]
  end

  def prefix
    @klass.to_s
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1E\e[1A\e[K"
  end
end

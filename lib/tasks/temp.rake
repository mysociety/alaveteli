namespace :temp do
  desc 'Migrate PublicBody notes into Note model'
  task migrate_public_body_notes: :environment do
    scope = PublicBody.where.not(notes: nil)
    count = scope.count

    scope.with_translations.find_each.with_index do |body, index|
      PublicBody.transaction do
        body.legacy_note&.save
        body.translations.update(notes: nil)
      end

      erase_line
      print "Migrated PublicBody#notes #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrated PublicBody#notes completed."
  end

  desc 'Populate incoming message from email'
  task populate_incoming_message_from_email: :environment do
    scope = IncomingMessage.where(from_email: nil)
    count = scope.count

    scope.includes(:raw_email).find_each.with_index do |message, index|
      message.update_columns(from_email: message.raw_email.from_email || '')

      erase_line
      print "Populated IncomingMessage#from_email #{index + 1}/#{count}"
    end

    erase_line
    puts "Populated IncomingMessage#from_email completed."
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end

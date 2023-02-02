namespace :temp do
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

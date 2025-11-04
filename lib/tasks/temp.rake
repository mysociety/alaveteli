namespace :temp do
  desc 'Populate User#status_update_count'
  task populate_user_status_update_count: :environment do
    scope = User.all
    count = scope.count

    scope.find_each.with_index do |user, index|
      update_count = InfoRequestEvent.
        where(event_type: 'status_update').
        where("params -> 'user' ->> 'gid' = ?", user.to_gid.to_s).
        count

      user.update_columns(status_update_count: update_count)

      erase_line
      print "Populating User#status_update_count #{index + 1}/#{count}"
    end

    erase_line
    puts "Populating User#status_update_count completed."
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end

namespace :temp do
  desc 'Migrate current User#url_name to new slug model'
  task migrate_user_slugs: :environment do
    scope = User.left_joins(:slugs).where(slugs: { id: nil })
    count = scope.count

    scope.find_each.with_index do |user, index|
      user.slugs.create!(slug: user.url_name)

      erase_line
      print "Migrate User#url_name to User#slugs #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrating to User#slugs completed."
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end

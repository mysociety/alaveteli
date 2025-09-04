namespace :users do
  namespace :pro do
    desc 'Ensure all pro have the correct features enabled'
    task enable_features: :environment do
      User.pro.map { |u| u.features.assign_role_features }
    end
  end

  desc 'CSV containing count of users per email domain, most popular first'
  task count_per_domain: :environment do
    from = ENV["START_DATE"]

    results = UserStats.list_user_domains(start_date: from)

    puts %w(domain count_of_users).to_csv

    results.each do |result|
      puts [result['domain'], result['count']].to_csv
    end
  end

  desc "Lists per domain stats"
  task stats_by_domain: :environment do
    raise "must supply a DOMAIN value" unless ENV["DOMAIN"]
    domain = ENV["DOMAIN"]
    from = ENV["START_DATE"]

    users = User.where("email like ?", "%@#{domain}")
    users = users.where("created_at >= ?", from) if from

    total_users = users.count
    banned = users.banned.count

    banned_percent = if total_users == 0
      0
    else
      (banned.to_f / total_users * 100).round(2)
    end

    dormant = UserStats.count_dormant_users(domain, from)

    dormant_percent = if total_users == 0
      0
    else
      (dormant.to_f / total_users * 100).round(2)
    end

    p "Since #{from}..." if from
    p "total users: #{total_users}"
    p "   banned %: #{banned} (#{banned_percent}%)"
    p "  dormant %: #{dormant} (#{dormant_percent}%)"
  end

  desc "Bans all users for a specific domain"
  task ban_by_domain: :environment do
    raise "must supply a DOMAIN value" unless ENV["DOMAIN"]
    domain = ENV["DOMAIN"]
    from = ENV["START_DATE"]

    Rake.application.invoke_task("users:stats_by_domain")

    p ""

    message = "Do you want to ban all the non-admin users for #{domain}"
    message += " created on or after #{from}" if from
    message += "(y/N)"
    p message
    input = STDIN.gets.strip

    if input.downcase == "y"
      to_ban = UserStats.unbanned_by_domain(domain, from)
      count = to_ban.
        update_all(ban_text: "Banned for spamming")
      p "#{count} accounts banned"
    else
      p "No action taken"
    end
  end

  desc <<-EOF
  A list of most-active to least-active pro users.

  START_DATE: Specify the start of the period of activity to consider
  END_DATE: Specify the end of the period of activity to consider
  FIELDS: A CSV list of User attributes to print
          (default: "id,name,email,activity")
  EOF
  task pro_activity: :environment do
    fields =
      if ENV['FIELDS']
        ENV['FIELDS'].split(',').map(&:strip)
      else
        %w(id name email activity)
      end

    start_date =
      if ENV['START_DATE']
        Time.zone.parse(ENV['START_DATE']).at_beginning_of_day
      end

    end_date =
      (Time.zone.parse(ENV['END_DATE']).at_end_of_day if ENV['END_DATE'])

    # Only auto-calculate missing dates if one has been provided without the
    # other
    if start_date || end_date
      # If we don't have a start_date, set it to the earliest created User as
      # there can't be events before that
      start_date ||= User.minimum(:created_at)

      # If we don't have an end_date, set it to now.
      end_date ||= Time.zone.now
    end

    # Only create a date filter if one has been requested through the
    # environment
    between = start_date..end_date if start_date && end_date

    query = User::WithActivityQuery.new
    query = between ? query.call(between) : query.call
    users = query.pro.order(activity: :desc)

    # We can't `#pluck` activity because its not a real attribute, so we fall
    # back to a slower `#map`.
    users =
      if fields.include?('activity')
        users.map { |user| fields.map { |field| user.send(field) } }
      else
        users.pluck(*fields)
      end

    csv_string = CSV.generate do |csv|
      csv << fields
      users.each { |user| csv << Array(user) }
    end

    puts csv_string
  end

  desc 'Update hashed password to the latest algorithm (bcrypt)'
  task update_hashed_password: :environment do
    User.sha1.find_each { |user| user.update(password: user.hashed_password) }
  end

  desc 'Purge profile content from limited users'
  task purge_limited: :environment do
    users = User.limited_profile.where(created_at: ...6.months.ago)

    users_with_about_me = users.where.not(about_me: '')
    users_with_profile_photos = users.joins(:profile_photo)
    ids = users_with_about_me.ids + users_with_profile_photos.ids

    users_with_about_me.update_all(about_me: '')
    ProfilePhoto.joins(:user).merge(users_with_profile_photos).destroy_all

    ActiveRecord::Base.logger.silence do
      User.where(id: ids).in_batches.each_record(&:xapian_mark_needs_index)
    end
  end

  desc 'Destroy user accounts that have not created any content'
  task destroy_unused: :environment do
    users = User.unused.where(created_at: ...2.years.ago)
    users.destroy_all
  end
end

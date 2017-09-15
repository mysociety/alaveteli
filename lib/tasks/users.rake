# -*- encoding : utf-8 -*-
namespace :users do

  desc "Lists email domains, most popular first"
  task :count_per_domain => :environment do
    from = ENV["START_DATE"]

    results = UserStats.list_user_domains(:start_date => from)

    column1_width = results.map { |x| x["domain"].length }.sort.last

    p "Since #{from}..." if from

    p " domain ".ljust(column1_width + 2, " ") + " | " + " count "
    p "--------".ljust(column1_width + 2, "-") + " | " + "-------"

    results.each do |result|
      p " #{result["domain"].ljust(column1_width, " ")}  |  #{result["count"]}"
    end

  end

  desc "Lists per domain stats"
  task :stats_by_domain => :environment do
    raise "must supply a DOMAIN value" unless ENV["DOMAIN"]
    domain = ENV["DOMAIN"]
    from = ENV["START_DATE"]

    total_users = if from
      User.where("email LIKE ?", "%@#{domain}").
        where("created_at >= ?", from).
        count
    else
      User.where("email LIKE ?", "%@#{domain}").
        count
    end

    banned = if from
      User.where("email like ?", "%@#{domain}").
        where("ban_text != ''").
        where("created_at >= ?", from).
        count
    else
      User.where("email like ?", "%@#{domain}").
        where("ban_text != ''").
        count
    end

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
  task :ban_by_domain => :environment do
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
        update_all(:ban_text => "Banned for spamming")
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
  task :pro_activity => :environment do
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
      if ENV['END_DATE']
        Time.zone.parse(ENV['END_DATE']).at_end_of_day
      end

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
    users = query.pro.order('activity DESC')

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
end

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
        where(:admin_level => 'none').
        where("created_at >= ?", from).
        count
    else
      User.where("email LIKE ?", "%@#{domain}").
        where(:admin_level => 'none').
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
      (banned.to_f / total_users * 100).round
    end

    # When we have Rails 4 across the board, we get to say "where.not" and
    # we rewrite this using the ORM
    # example code here: http://stackoverflow.com/a/23389130), until then...
    #
    # Reminder - check that the returned ids in the subquery does not include
    # null values otherwise this will unexpectedly return 0
    # (see http://stackoverflow.com/a/19528722) this should not be a thing but
    # is happening on WDTK with the info_requests table for some reason
    sql = "SELECT count(*) FROM users " \
          "WHERE id NOT IN ( " \
          "  SELECT DISTINCT user_id FROM info_requests " \
          "  WHERE user_id IS NOT NULL " \
          ") AND id NOT IN ( " \
          "  SELECT DISTINCT tracking_user_id FROM track_things " \
          "  WHERE tracking_user_id IS NOT NULL " \
          ") AND id NOT IN ( " \
          "  SELECT DISTINCT user_id FROM comments " \
          "  WHERE user_id IS NOT NULL " \
          ") AND email LIKE '%@#{domain}'"
    sql += "AND created_at >= '#{from}'" if from
    dormant = User.connection.select_all(sql).first["count"]

    dormant_percent = if total_users == 0
      0
    else
      (dormant.to_f / total_users * 100).round
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

    message = "Do you want to ban all the users for #{domain}"
    message += " created on or after #{from}" if from
    message += "(y/N)"
    p message
    input = STDIN.gets.strip

    if input.downcase == "y"
      count = if from
        User.where("email like ?", "%@#{domain}").
             where(:admin_level => 'none').
             where("created_at >= ?", from).
             update_all(:ban_text => "Banned for use of #{domain} email")
      else
        User.where("email like ?", "%@#{domain}").
             where(:admin_level => 'none').
             update_all(:ban_text => "Banned for use of #{domain} email")
    end
      p "#{count} accounts banned"
    else
      p "No action taken"
    end
  end

end

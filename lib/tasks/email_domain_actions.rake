# -*- encoding : utf-8 -*-
namespace :email_domain_actions do

  desc "Lists top 20 most used email domains"
  task :top20 => :environment do
    # the limit of 20 is fairly arbitrary but I imagine this being more
    # annoying than useful otherwise

    from = ENV["START_DATE"]

    sql = if from
      "SELECT substring(email, position('@' in email)+1) AS domain, " \
      "COUNT(id) AS count " \
      "FROM users " \
      "WHERE admin_level = 'none' AND created_at >= '#{from}' " \
      "GROUP BY domain " \
      "ORDER BY count DESC " \
      "LIMIT 20"
    else
      "SELECT substring(email, position('@' in email)+1) AS domain, " \
      "COUNT(id) AS count " \
      "FROM users " \
      "WHERE admin_level = 'none' " \
      "GROUP BY domain " \
      "ORDER BY count DESC " \
      "LIMIT 20"
    end
    results = User.connection.select_all(sql)

    column1_width = results.map { |x| x["domain"].length }.sort.last

    p "Since #{from}..." if from

    p " domain ".ljust(column1_width + 2, " ") + " | " + " count "
    p "--------".ljust(column1_width + 2, "-") + " | " + "-------"

    results.each do |result|
      p " #{result["domain"].ljust(column1_width, " ")}  |  #{result["count"]}"
    end

  end

  desc "Lists per domain stats"
  task :stats => :environment do
    raise "must supply a DOMAIN value" unless ENV["DOMAIN"]
    domain = ENV["DOMAIN"]
    from = ENV["START_DATE"]

    total_users = if from
      User.where("email like ?", "%@#{domain}").
           where(:admin_level => 'none').
           where("created_at >= ?", from).
           count
    else
      User.where("email like ?", "%@#{domain}").
           where(:admin_level => 'none').
           count
    end

    spammers = if from
      User.where("email like ?", "%@#{domain}").
           where("ban_text != ''").
           where("created_at >= ?", from).
           count
    else
      User.where("email like ?", "%@#{domain}").
           where("ban_text != ''").
           count
    end

    spam_percent = if total_users == 0
      0
    else
      (spammers.to_f / total_users * 100).round
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
          ") AND email like '%@#{domain}'"
    sql += "AND created_at >= '#{from}'" if from
    dormant = User.connection.select_all(sql).first["count"]

    dormant_percent = if total_users == 0
      0
    else
      (dormant.to_f / total_users * 100).round
    end

    p "Since #{from}..." if from
    p "total users: #{total_users}"
    p "     spam %: #{spam_percent}% (#{spammers})"
    p "  dormant %: #{dormant_percent}% (#{dormant})"
  end

  desc "Bans all users for a specific domain"
  task :ban_users => :environment do
    raise "must supply a DOMAIN value" unless ENV["DOMAIN"]
    domain = ENV["DOMAIN"]
    from = ENV["START_DATE"]

    Rake.application.invoke_task("email_domain_actions:stats")

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

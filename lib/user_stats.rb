# -*- encoding : utf-8 -*-
#
# Public: methods for getting stats about users on a per domain basis

class UserStats

  # Returns a list of email domains people have used to sign up with and the
  # number of signups for each, ordered by popularity (most popular first)
  def self.list_user_domains(params={})
    sql = if params[:start_date]
      "SELECT substring(email, position('@' in email)+1) AS domain, " \
      "COUNT(id) AS count " \
      "FROM users " \
      "WHERE admin_level = 'none' AND created_at >= '#{params[:start_date]}' " \
      "GROUP BY domain " \
      "ORDER BY count DESC "
    else
      "SELECT substring(email, position('@' in email)+1) AS domain, " \
      "COUNT(id) AS count " \
      "FROM users " \
      "WHERE admin_level = 'none' " \
      "GROUP BY domain " \
      "ORDER BY count DESC "
    end
    sql = "#{sql} LIMIT #{params[:limit]}" if params[:limit]

    User.connection.select_all(sql)
  end

end

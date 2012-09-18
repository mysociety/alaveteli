# Use this file to easily define all of your cron jobs.

# TODO: Replace run-with-lockfile command with something more Rubyesque
job_type :run_with_lockfile, "cd :path && RAILS_ENV=:environment run-with-lockfile -n ./:lockfile_name.lock :task || echo \"stalled?\""

every 5.minutes do
  # TODO: Replace with Raketask xapian:rebuild_index
  run_with_lockfile "\"./script/update-xapian-index verbose=true\" >> ./log/update-xapian-index.log", :lockfile_name => 'change-xapian-database'
end

# TODO:
# # Every 10 minutes
# 5,15,25,35,45,55 * * * * !!(*= $user *)!! /etc/init.d/foi-alert-tracks check
# 5,15,25,35,45,55 * * * * !!(*= $user *)!! /etc/init.d/foi-purge-varnish check

every :hour, :at => 9 do
  # TODO: Replace script with runner task that Whenever natively supports
  run_with_lockfile './script/alert-comment-on-request', :lockfile_name => 'alert-comment-on-request'
end

# # Only root can read the exim log files
# 31 * * * * root run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/load-exim-logs.lock /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/load-exim-logs || echo "stalled?"

# # Once a day, early morning
# 23 4 * * * !!(*= $user *)!! run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/delete-old-things.lock /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/delete-old-things || echo "stalled?"
# 0 6 * * * !!(*= $user *)!! run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/alert-overdue-requests.lock /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/alert-overdue-requests || echo "stalled?"
# 0 7 * * * !!(*= $user *)!! run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/alert-new-response-reminders.lock /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/alert-new-response-reminders || echo "stalled?"
# 0 8 * * * !!(*= $user *)!! run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/alert-not-clarified-request.lock /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/alert-not-clarified-request || echo "stalled?"
# 2 4 * * * !!(*= $user *)!! run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/check-recent-requests-sent.lock /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/check-recent-requests-sent || echo "stalled?"
# 45 3 * * * !!(*= $user *)!! run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/stop-new-responses-on-old-requests.lock /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/stop-new-responses-on-old-requests || echo "stalled?"
# # Only root can restart apache
# 31 1 * * * root run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/change-xapian-database.lock "/data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/compact-xapian-database production" || echo "stalled?"


# # Once a day on all servers
# 43 2 * * * !!(*= $user *)!! /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/request-creation-graph
# 48 2 * * * !!(*= $user *)!! /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/user-use-graph

# # Once a year :)
# @yearly !!(*= $user *)!! /bin/echo "A year has passed, please update the bank holidays for the Freedom of Information site, thank you."

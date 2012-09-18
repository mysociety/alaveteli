# Use this file to easily define all of your cron jobs.

# TODO: Replace run-with-lockfile command with something more Rubyesque
job_type :run_with_lockfile, "cd :path && RAILS_ENV=:environment run-with-lockfile -n ./:lockfile_name.lock :task || echo \"stalled?\""

every 5.minutes do
  # TODO: Replace with Raketask xapian:rebuild_index
  run_with_lockfile "\"./script/update-xapian-index verbose=true\" >> ./log/update-xapian-index.log", :lockfile_name => 'change-xapian-database'
end

every 10.minutes do
  command '/etc/init.d/foi-alert-tracks check'
  command '/etc/init.d/foi-purge-varnish check'
end

every :hour, :at => 9 do
  # TODO: Replace script with runner task that Whenever natively supports
  run_with_lockfile './script/alert-comment-on-request', :lockfile_name => 'alert-comment-on-request'
end

every :hour, :at => 31 do
  # TODO: Add instructions about needing permissions to do this. The original
  # crontab specified running as root which does not sounds like A Good Idea
  run_with_lockfile './script/load-exim-logs', :lockfile_name => 'load-exim-logs'
end

every :day, :at => '04:23' do
  # TODO: Replace script with runner task that Whenever natively supports
  run_with_lockfile './script/delete-old-things', :lockfile_name => 'delete-old-things'
end

every :day, :at => '06:00' do
  # TODO: Replace script with runner task that Whenever natively supports
  run_with_lockfile './script/alert-overdue-requests', :lockfile_name => 'alert-overdue-requests'
end

every :day, :at => '07:00' do
  # TODO: Replace script with runner task that Whenever natively supports
  run_with_lockfile './script/alert-new-response-reminders', :lockfile_name => 'alert-new-response-reminders'
end

every :day, :at => '08:00' do
  # TODO: Replace script with runner task that Whenever natively supports
  run_with_lockfile './script/alert-not-clarified-request', :lockfile_name => 'alert-not-clarified-request'
end

every :day, :at => '04:02' do
  # TODO: Replace script with runner task that Whenever natively supports
  run_with_lockfile './script/check-recent-requests-sent', :lockfile_name => 'check-recent-requests-sent'
end

every :day, :at => '03:45' do
  # TODO: Replace script with runner task that Whenever natively supports
  run_with_lockfile './script/stop-new-responses-on-old-requests', :lockfile_name => 'stop-new-responses-on-old-requests'
end

# # Once a day, early morning
# # Only root can restart apache
# 31 1 * * * root run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/change-xapian-database.lock "/data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/compact-xapian-database production" || echo "stalled?"


# # Once a day on all servers
# 43 2 * * * !!(*= $user *)!! /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/request-creation-graph
# 48 2 * * * !!(*= $user *)!! /data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/user-use-graph

# # Once a year :)
# @yearly !!(*= $user *)!! /bin/echo "A year has passed, please update the bank holidays for the Freedom of Information site, thank you."

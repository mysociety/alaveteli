# Use this file to easily define all of your cron jobs.

# TODO: Replace run-with-lockfile command with something more Rubyesque
job_type :run_script_with_lockfile, "cd :path && RAILS_ENV=:environment run-with-lockfile -n ./:task ./script/:task || echo \"stalled?\""

job_type :command_in_current_release, "cd :path && RAILS_ENV=:environment :task :output"

every 5.minutes do
  # TODO: Replace with Raketask xapian:rebuild_index
  command_in_current_release "run-with-lockfile -n ./update-xapian-index.lock \"./script/update-xapian-index verbose=true\" >> ./log/update-xapian-index.log || echo \"stalled?\""
end

every 10.minutes do
  command '/etc/init.d/foi-alert-tracks check'
  command '/etc/init.d/foi-purge-varnish check'
end

every :hour, :at => 9 do
  run_script_with_lockfile 'alert-comment-on-request'
end

every :hour, :at => 31 do
  # TODO: Add instructions about needing permissions to do this. The original
  # crontab specified running as root which does not sounds like A Good Idea
  run_script_with_lockfile 'load-exim-logs'
end

every :day, :at => '04:23' do
  run_script_with_lockfile 'delete-old-things'
end

every :day, :at => '06:00' do
  run_script_with_lockfile 'alert-overdue-requests'
end

every :day, :at => '07:00' do
  run_script_with_lockfile 'alert-new-response-reminders'
end

every :day, :at => '08:00' do
  run_script_with_lockfile 'alert-not-clarified-request'
end

every :day, :at => '04:02' do
  run_script_with_lockfile 'check-recent-requests-sent'
end

every :day, :at => '03:45' do
  run_script_with_lockfile 'stop-new-responses-on-old-requests'
end

# # Once a day, early morning
# # Only root can restart apache
# 31 1 * * * root run-with-lockfile -n /data/vhost/!!(*= $vhost *)!!/change-xapian-database.lock "/data/vhost/!!(*= $vhost *)!!/!!(*= $vcspath *)!!/script/compact-xapian-database production" || echo "stalled?"

every :day, :at => '02:43' do
  command_in_current_release './script/request-creation-graph'
end

every :day, :at => '02:48' do
  command_in_current_release './script/user-use-graph'
end

every :year do
  command '/bin/echo "A year has passed, please update the bank holidays for the Freedom of Information site, thank you."'
end

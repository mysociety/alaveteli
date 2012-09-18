# Use this file to easily define all of your cron jobs.

job_type :command_in_current_release, "cd :path && RAILS_ENV=:environment :task :output"

every 5.minutes do
  # TODO: Replace run-with-lockfile command with something more Rubyesque
  # TODO: Replace with Raketask xapian:rebuild_index
  command_in_current_release "run-with-lockfile -n ./change-xapian-database.lock \"./script/update-xapian-index verbose=true\" >> ./log/update-xapian-index.log || echo \"stalled?\""
end

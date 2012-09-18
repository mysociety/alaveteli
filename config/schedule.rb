# Use this file to easily define all of your cron jobs.

every 5.minutes do
  # TODO: Replace run-with-lockfile command with something more Rubyesque
  # TODO: Replace with Raketask xapian:rebuild_index
  command "run-with-lockfile -n #{Whenever.path}/change-xapian-database.lock \"#{Whenever.path}/script/update-xapian-index verbose=true\" >> #{Whenever.path}/logs/update-xapian-index.log || echo \"stalled?\""
end

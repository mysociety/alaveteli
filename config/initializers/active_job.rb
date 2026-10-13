ActiveSupport.on_load(:active_job) do
  # Rails 8.2 default, adopted early. Enqueuing during a transaction races
  # Sidekiq, which picks the job up on another connection and can't see
  # anything the transaction hasn't committed.
  self.enqueue_after_transaction_commit = true
end

class NullStaleOtpCounters < ActiveRecord::Migration[8.0]
  # The matched set is the whole "never enrolled in 2FA" cohort, which
  # is most of `users` on a typical install. Batched updates outside a
  # wrapping transaction keep locks short and let a re-run resume from
  # where a previous run left off — the filter is idempotent.
  disable_ddl_transaction!

  def up
    User.where(otp_enabled: false).
      where.not(otp_counter: nil).
      in_batches(of: 1000) do |batch|
        batch.update_all(otp_counter: nil)
      end
  end

  def down
    # Original counter values cannot be reconstructed.
  end
end

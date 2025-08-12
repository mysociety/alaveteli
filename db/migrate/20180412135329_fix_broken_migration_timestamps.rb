class FixBrokenMigrationTimestamps < ActiveRecord::Migration[4.2]
  def up
    # We can just delete the old migration version from the database beacuse:
    # * We know the renamed migration has been applied, because the timestamp
    #   is less than the timestamp of this migration.
    # * The renamed migration will be a no-op, because the columns already exist
    #   and we handle that in the renamed migration files.
    # * The badly-named migration files no longer exist.
    if migration_exist?('20170718261524_add_expiring_notification_at.rb')
      execute(<<-SQL)
      DELETE FROM schema_migrations
      WHERE version = '2017071826152436'
      SQL
    end

    if migration_exist?('20170825150448_add_stripe_customer_id_to_pro_account.rb')
      execute(<<-SQL)
      DELETE FROM schema_migrations
      WHERE version = '2017082515044823'
      SQL
    end
  end

  def down
    # Here, we need to revert to the badly-named migrations, because the files
    # will still exist.
    if migration_exist?('2017071826152436_add_expiring_notification_at.rb')
      execute(<<-SQL)
      UPDATE schema_migrations
      SET version = '2017071826152436'
      WHERE version = '20170718152436'
      SQL
    end

    if migration_exist?('2017082515044823_add_stripe_customer_id_to_pro_account.rb')
      execute(<<-SQL)
      UPDATE schema_migrations
      SET version = '2017082515044823'
      WHERE version = '20170825150448'
      SQL
    end
  end

  private

  def migration_exist?(migration_file)
    File.exist?(Rails.root + "db/migrate/#{ migration_file }")
  end
end

# In order to work around the problem of the database use not having
# the permission to disable referential integrity when loading fixtures,
# we redefine disable_referential_integrity so that it doesn't try to
# disable foreign key constraints, and redefine the
# ActiveRecord::FixtureSet.create_fixtures method to pay attention to the order
# which fixture tables are passed so that foreign key constraints won't be
# violated. The only lines that are changed from the initial definition
# are those between the "***" comments
require 'active_record/fixtures'
require 'active_record/connection_adapters/postgresql_adapter'
module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < AbstractAdapter
      module ReferentialIntegrity
        def disable_referential_integrity
          transaction {
            yield
          }
        end
      end
    end
  end
end

module ActiveRecord
  class FixtureSet

    def self.create_fixtures(fixtures_directory, fixture_set_names, class_names = {}, config = ActiveRecord::Base)
      fixture_set_names = Array(fixture_set_names).map(&:to_s)
      class_names = ClassCache.new class_names, config

      # FIXME: Apparently JK uses this.
      connection = block_given? ? yield : ActiveRecord::Base.connection

      files_to_read = fixture_set_names.reject { |fs_name|
        fixture_is_cached?(connection, fs_name)
      }

      unless files_to_read.empty?
        connection.disable_referential_integrity do
          fixtures_map = {}

          fixture_sets = files_to_read.map do |fs_name|
            klass = class_names[fs_name]
            conn = klass ? klass.connection : connection
            fixtures_map[fs_name] = new( # ActiveRecord::FixtureSet.new
              conn,
              fs_name,
              klass,
              ::File.join(fixtures_directory, fs_name))
          end

          update_all_loaded_fixtures fixtures_map

          connection.transaction(:requires_new => true) do
            # Patch - replace this...
            # ***
            # fixture_sets.each do |fs|
            #   conn = fs.model_class.respond_to?(:connection) ? fs.model_class.connection : connection
            #   table_rows = fs.table_rows

            #   table_rows.keys.each do |table|
            #     conn.delete "DELETE FROM #{conn.quote_table_name(table)}", 'Fixture Delete'
            #   end

            #   table_rows.each do |fixture_set_name, rows|
            #     rows.each do |row|
            #       conn.insert_fixture(row, fixture_set_name)
            #     end
            #   end

            #   # Cap primary key sequences to max(pk).
            #   if conn.respond_to?(:reset_pk_sequence!)
            #     conn.reset_pk_sequence!(fs.table_name)
            #   end
            # end
            # ***
            # ... with this
            fixture_sets.reverse.each do |fs|
              conn = fs.model_class.respond_to?(:connection) ? fs.model_class.connection : connection
              table_rows = fs.table_rows

              table_rows.keys.each do |table|
                conn.delete "DELETE FROM #{conn.quote_table_name(table)}", 'Fixture Delete'
              end
            end

            fixture_sets.each do |fs|
              conn = fs.model_class.respond_to?(:connection) ? fs.model_class.connection : connection
              table_rows = fs.table_rows
              table_rows.each do |table_name,rows|
                rows.each do |row|
                  conn.insert_fixture(row, table_name)
                end
              end

              # Cap primary key sequences to max(pk).
              if conn.respond_to?(:reset_pk_sequence!)
                conn.reset_pk_sequence!(fs.table_name)
              end
            end
            # ***
          end

          cache_fixtures(connection, fixtures_map)
        end
      end
      cached_fixtures(connection, fixture_set_names)
    end

  end
end

# -*- encoding : utf-8 -*-
require 'active_record/fixtures'

module ActiveRecord
  class FixtureSet

    # WIP test a monkeypatch for Ruby 2.3.x
    # Applies https://github.com/rails/rails/commit/d6d63767795dd5c47a57d37d075
    #
    # Return a hash of rows to be inserted. The key is the table, the value is
    # a list of rows to insert to that table.
    def table_rows
      now = ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now
      now = now.to_s(:db)

      # allow a standard key to be used for doing defaults in YAML
      fixtures.delete('DEFAULTS')

      # track any join tables we need to insert later
      rows = Hash.new { |h,table| h[table] = [] }

      rows[table_name] = fixtures.map do |label, fixture|
        row = fixture.to_hash

        if model_class && model_class < ActiveRecord::Base
          # fill in timestamp columns if they aren't specified and the model is set to record_timestamps
          if model_class.record_timestamps
            timestamp_column_names.each do |c_name|
              row[c_name] = now unless row.key?(c_name)
            end
          end

          # interpolate the fixture label
          row.each do |key, value|
            row[key] = label if "$LABEL" == value
          end

          # generate a primary key if necessary
          if has_primary_key_column? && !row.include?(primary_key_name)
            row[primary_key_name] = ActiveRecord::FixtureSet.identify(label)
          end

          # If STI is used, find the correct subclass for association reflection
          reflection_class =
            if row.include?(inheritance_column_name)
              begin
                row[inheritance_column_name].constantize
              rescue
                model_class
              end
            else
              model_class
            end

          reflection_class.reflect_on_all_associations.each do |association|
            case association.macro
            when :belongs_to
              # Do not replace association name with association foreign key if they are named the same
              fk_name = (association.options[:foreign_key] || "#{association.name}_id").to_s

              if association.name.to_s != fk_name && value = row.delete(association.name.to_s)
                if association.options[:polymorphic] && value.sub!(/\s*\(([^\)]*)\)\s*$/, "")
                  # support polymorphic belongs_to as "label (Type)"
                  row[association.foreign_type] = $1
                end

                row[fk_name] = ActiveRecord::FixtureSet.identify(value)
              end
            when :has_and_belongs_to_many
              if (targets = row.delete(association.name.to_s))
                targets = targets.is_a?(Array) ? targets : targets.split(/\s*,\s*/)
                table_name = association.join_table
                rows[table_name].concat targets.map { |target|
                  { association.foreign_key             => row[primary_key_name],
                    association.association_foreign_key => ActiveRecord::FixtureSet.identify(target) }
                }
              end
            end
          end
        end

        row
      end
      rows
    end
  end
end

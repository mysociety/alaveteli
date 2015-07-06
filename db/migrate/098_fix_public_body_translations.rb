# -*- encoding : utf-8 -*-
# The PublicBody model class had a bug that meant the
# translations for first_letter and publication_scheme
# were not being correctly populated.
#
# This migration fixes up the data to correct this.
#
# Note that the "update ... from" syntax is a Postgres
# extension to SQL.

class FixPublicBodyTranslations < ActiveRecord::Migration
    def self.up
      execute <<-SQL
        update public_body_translations
        set first_letter = upper(substr(name, 1, 1))
        where first_letter is null
        ;
      SQL

      execute <<-SQL
        update public_body_translations
          set publication_scheme = (SELECT public_bodies.publication_scheme FROM public_bodies WHERE
public_body_translations.public_body_id = public_bodies.id )
        where public_body_translations.publication_scheme is null
        ;
      SQL
    end

    def self.down
        # This is a bug-fix migration, that does not involve a schema change.
        # It doesn't make sense to reverse it.
    end
end



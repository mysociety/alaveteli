# -*- encoding : utf-8 -*-
class EmailIsUnique < ActiveRecord::Migration
    def self.up
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "create unique index users_email_index on users (lower(email))"

            # Don't need these any more, with new special url_name fields
            execute 'drop index users_url_name_index'
            execute 'drop index public_bodies_url_short_name_index'
            execute 'drop index public_body_versions_url_short_name_index'
        end
    end

    def self.down
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "drop index users_email_index"

            execute "create index public_bodies_url_short_name_index on public_bodies(regexp_replace(replace(lower(short_name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"
            execute "create index public_body_versions_url_short_name_index on public_body_versions(regexp_replace(replace(lower(short_name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"
            execute "create index users_url_name_index on users (regexp_replace(replace(lower(name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"
        end
    end
end

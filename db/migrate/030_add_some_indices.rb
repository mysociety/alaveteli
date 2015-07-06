# -*- encoding : utf-8 -*-
class AddSomeIndices < ActiveRecord::Migration
    def self.up
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute 'create index users_lower_email_index on users(lower(email))'
        end

        add_index :info_requests, :created_at
        # MySQL cannot index text blobs like this
        if ActiveRecord::Base.connection.adapter_name != "MySQL"
            add_index :info_requests, :title # For checking duplicates at new request time
        end

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "create index public_bodies_url_short_name_index on public_bodies(regexp_replace(replace(lower(short_name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"
            execute "create index public_body_versions_url_short_name_index on public_body_versions(regexp_replace(replace(lower(short_name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"
            execute "create index users_url_name_index on users (regexp_replace(replace(lower(name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"
        end

        # MySQL cannot index text blobs like this
        if ActiveRecord::Base.connection.adapter_name != "MySQL"
            add_index :post_redirects, :email_token
            add_index :post_redirects, :token
        end
    end

    def self.down
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute 'drop index users_lower_email_index'
        end

        remove_index :info_requests, :created_at
        if ActiveRecord::Base.connection.adapter_name != "MySQL"
            remove_index :info_requests, :title 
        end

        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute 'drop index users_url_name_index'
            execute 'drop index public_bodies_url_short_name_index'
            execute 'drop index public_body_versions_url_short_name_index'
        end

        if ActiveRecord::Base.connection.adapter_name != "MySQL"
            remove_index :post_redirects, :email_token
            remove_index :post_redirects, :token
        end
    end
end

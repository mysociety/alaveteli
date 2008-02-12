class AddSomeIndices < ActiveRecord::Migration
    def self.up
        execute 'create index users_lower_email_index on users(lower(email))'

        add_index :info_requests, :created_at
        add_index :info_requests, :title # For checking duplicates at new request time

        execute "create index public_bodies_url_short_name_index on public_bodies(regexp_replace(replace(lower(short_name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"
        execute "create index public_body_versions_url_short_name_index on public_body_versions(regexp_replace(replace(lower(short_name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"
        execute "create index users_url_name_index on users (regexp_replace(replace(lower(name), ' ', '-'), '[^a-z0-9_-]', '', 'g'))"

        add_index :post_redirects, :email_token
        add_index :post_redirects, :token

    end

    def self.down
        execute 'drop index users_lower_email_index'

        remove_index :info_requests, :created_at
        remove_index :info_requests, :title 

        execute 'drop index users_url_name_index'
        execute 'drop index public_bodies_url_short_name_index'
        execute 'drop index public_body_versions_url_short_name_index'

        remove_index :post_redirects, :email_token
        remove_index :post_redirects, :token
    end
end

class AddInfoRequestsCountToPublicBodies < ActiveRecord::Migration
  def self.up
      add_column :public_bodies, :info_requests_count, :integer, :null => false, :default => 0

      PublicBody.reset_column_information

      PublicBody.find_each do |public_body|
          public_body.update_attribute :info_requests_count, public_body.info_requests.length
      end

  end

  def self.down
      remove_column :public_bodies, :info_requests_count
  end

end

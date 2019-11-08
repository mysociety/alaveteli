# == Schema Information
# Schema version: 20220322100510
#
# Table name: request_classifications
#
#  id                    :bigint           not null, primary key
#  user_id               :bigint
#  info_request_event_id :bigint
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class RequestClassification < ApplicationRecord
  belongs_to :user,
             :inverse_of => :request_classifications,
             :counter_cache => true
  belongs_to :info_request_event,
             :inverse_of => :request_classification

  # return classification instances representing the top n
  # users, with a 'cnt' attribute representing the number
  # of classifications the user has made.
  def self.league_table(size, conditions=nil)
    query = select('user_id, count(*) as cnt').
      group('user_id').
        order('cnt desc').
          limit(size).
            includes(:user)
    query = query.where(*conditions) if conditions
    query
  end

end

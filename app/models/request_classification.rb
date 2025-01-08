# == Schema Information
# Schema version: 20210114161442
#
# Table name: request_classifications
#
#  id                    :integer          not null, primary key
#  user_id               :integer
#  info_request_event_id :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class RequestClassification < ApplicationRecord
  MILESTONES = [
    100, 250, 500, 1000, 2500, 5000, 10_000, 25_000, 50_000, 75_000, 100_000,
    250_000, 500_000, 750_000, 1_000_000
  ].freeze

  belongs_to :user,
             inverse_of: :request_classifications,
             counter_cache: true
  belongs_to :info_request_event,
             inverse_of: :request_classification

  # return classification instances representing the top n
  # users, with a 'cnt' attribute representing the number
  # of classifications the user has made.
  def self.league_table(size, conditions=nil)
    query = select('user_id, count(*) as cnt').
      group('user_id').
        order(cnt: :desc).
          limit(size).
            joins(:user).
              merge(User.active)
    query = query.where(*conditions) if conditions
    query
  end
end

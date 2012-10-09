class RequestClassification < ActiveRecord::Base
    belongs_to :user

    # return classification instances representing the top n
    # users, with a 'cnt' attribute representing the number
    # of classifications the user has made.
    def RequestClassification.league_table(size, conditions=[])
        find(:all, :select => 'user_id, count(*) as cnt',
                                         :conditions => conditions,
                                         :group => 'user_id',
                                         :order => 'cnt desc',
                                         :limit => size,
                                         :include => :user)
    end

end
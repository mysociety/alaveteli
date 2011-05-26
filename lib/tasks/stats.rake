namespace :stats do 
  
  desc 'Produce transaction stats' 
  task :show => :environment do 
    month_starts = (Date.new(2009, 1)..Date.new(2011, 5)).select { |d| d.day == 1 }
    headers = ['Period',
               'Requests sent', 
               'Annotations added', 
               'Track this request email signups', 
               'Comments on own requests', 
               'Follow up messages sent']
    puts headers.join("\t")
    month_starts.each do |month_start|
      month_end = month_start.end_of_month
      period = "#{month_start}-#{month_end}"
      date_conditions = ['created_at >= ? 
                          AND created_at < ?', 
                          month_start, month_end+1]
      request_count = InfoRequest.count(:conditions => date_conditions)
      comment_count = Comment.count(:conditions => date_conditions)
      track_conditions = ['track_type = ? 
                           AND track_medium = ? 
                           AND created_at >= ? 
                           AND created_at < ?', 
                          'request_updates', 'email_daily', month_start, month_end+1]
      email_request_track_count = TrackThing.count(:conditions => track_conditions)
      comment_on_own_request_conditions = ['comments.user_id = info_requests.user_id 
                                            AND comments.created_at >= ? 
                                            AND comments.created_at < ?',
                                            month_start, month_end+1]
      comment_on_own_request_count = Comment.count(:conditions => comment_on_own_request_conditions,
                                                   :include => :info_request)
      
      followup_conditions = ['message_type = ? 
                               AND created_at >= ? 
                               AND created_at < ?',
                              'followup', month_start, month_end+1]
      follow_up_count = OutgoingMessage.count(:conditions => followup_conditions)
      puts [period, 
            request_count, 
            comment_count, 
            email_request_track_count, 
            comment_on_own_request_count, 
            follow_up_count].join("\t")
    end
  end
  
end
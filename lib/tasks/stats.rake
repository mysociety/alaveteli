namespace :stats do

  desc 'Produce monthly transaction stats for a period starting START_YEAR'
  task :show => :environment do
    example = 'rake stats:show START_YEAR=2009 [START_MONTH=3 END_YEAR=2012 END_MONTH=10]'
    check_for_env_vars(['START_YEAR'], example)
    start_year = (ENV['START_YEAR']).to_i
    start_month = (ENV['START_MONTH'] || 1).to_i
    end_year = (ENV['END_YEAR'] || Time.now.year).to_i
    end_month = (ENV['END_MONTH'] || Time.now.month).to_i
    month_starts = (Date.new(start_year, start_month)..Date.new(end_year, end_month)).select { |d| d.day == 1 }
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

  desc 'Produce stats on volume of requests to authorities matching a set of tags. Specify tags as TAGS=tagone,tagtwo'
  task :volumes_by_authority_tag => :environment do
    tags = ENV['TAGS'].split(',')
    first_request_datetime = InfoRequest.minimum(:created_at)
    start_year = first_request_datetime.strftime("%Y").to_i
    start_month = first_request_datetime.strftime("%m").to_i
    end_year = Time.now.strftime("%Y").to_i
    end_month = Time.now.strftime("%m").to_i
    puts "Start year: #{start_year}"
    puts "Start month: #{start_month}"
    puts "End year: #{end_year}"
    puts "End month: #{end_month}"
    public_bodies = []
    tags.each do |tag|
      tag_bodies = PublicBody.find_by_tag(tag)
      puts "Bodies with tag '#{tag}': #{tag_bodies.size}"
      public_bodies += tag_bodies
    end
    public_body_ids = public_bodies.map{ |body| body.id }.uniq
    public_body_condition_string = 'AND public_bodies.id in (?)'
    month_starts = (Date.new(start_year, start_month)..Date.new(end_year, end_month)).select { |d| d.day == 1 }
    headers = ['Period',
               'Requests sent',
               'Requests sent as % of total sent in period']
    puts headers.join("\t")
    month_starts.each do |month_start|
      month_end = month_start.end_of_month
      period = "#{month_start}-#{month_end}"
      date_condition_string = 'info_requests.created_at >= ? AND info_requests.created_at < ?'
      conditions = [date_condition_string + " " + public_body_condition_string,
                    month_start,
                    month_end+1,
                    public_body_ids]
      request_count = InfoRequest.count(:conditions => conditions,
                                        :include => :public_body)

      total_count = InfoRequest.count(:conditions => [date_condition_string, month_start, month_end+1])
      if total_count > 0
        percent = ((request_count.to_f / total_count.to_f ) * 100).round(2)
      else
        percent = 0.0
      end
      puts [period, request_count, percent].join("\t")
    end
  end

  desc <<-DESC
  Prints the per-quarter number of created FOI Requests made to each Public Body found by the query.
    Specify the search query as QUERY='london school'
  DESC
  task :number_of_requests_created => :environment do
    query = ENV['QUERY']
    start_at = PublicBody.minimum(:created_at)
    finish_at = PublicBody.maximum(:created_at)
    public_bodies = PublicBody.search(query)
    quarters = DateQuarter.quarters_between(start_at, finish_at)

    # Headers
    headers = ['Body'] + quarters.map { |date_tuple| date_tuple.join('~') }
    puts headers.join(",")

    public_bodies.each do |body|
      stats = quarters.map do |quarter|
        conditions = ['created_at >= ? AND created_at < ?', quarter[0], quarter[1]]
        count = body.info_requests.count(:conditions => conditions)
        count ? count : 0
      end

      row = [%Q("#{ body.name }")] + stats
      puts row.join(",")
    end
  end

  desc <<-DESC
  Prints the per-quarter number of successful FOI Requests made to each Public Body found by the query.
    Specify the search query as QUERY='london school'
  DESC
  task :number_of_requests_successful => :environment do
    query = ENV['QUERY']
    start_at = PublicBody.minimum(:created_at)
    finish_at = PublicBody.maximum(:created_at)
    public_bodies = PublicBody.search(query)
    quarters = DateQuarter.quarters_between(start_at, finish_at)

    # Headers
    headers = ['Body'] + quarters.map { |date_tuple| date_tuple.join('~') }
    puts headers.join(",")

    public_bodies.each do |body|
      stats = quarters.map do |quarter|
        conditions = ['created_at >= ? AND created_at < ? AND described_state = ?',
                      quarter[0], quarter[1], 'successful']
        count = body.info_requests.count(:conditions => conditions)
        count ? count : 0
      end

      row = [%Q("#{ body.name }")] + stats
      puts row.join(",")
    end
  end

  desc 'Update statistics in the public_bodies table'
  task :update_public_bodies_stats => :environment do
    verbose = ENV['VERBOSE'] == '1'
    PublicBody.find_each(:batch_size => 10) do |public_body|
      puts "Counting overdue requests for #{public_body.name}" if verbose

      # Look for values of 'waiting_response_overdue' and
      # 'waiting_response_very_overdue' which aren't directly in the
      # described_state column, and instead need to be calculated:
      overdue_count = 0
      very_overdue_count = 0
      InfoRequest.find_each(:batch_size => 200,
                            :conditions => {
                              :public_body_id => public_body.id,
                              :awaiting_description => false,
                              :prominence => 'normal'
      }) do |ir|
        case ir.calculate_status
        when 'waiting_response_very_overdue'
          very_overdue_count += 1
        when 'waiting_response_overdue'
          overdue_count += 1
        end
      end
      public_body.info_requests_overdue_count = overdue_count + very_overdue_count
      public_body.no_xapian_reindex = true
      public_body.without_revision do
        public_body.save!
      end
    end
  end

  desc 'Print a list of the admin URLs of requests with hidden material'
  task :list_hidden => :environment do
    include Rails.application.routes.url_helpers
    hidden_requests = InfoRequest.where(:prominence => 'hidden')
    requester_only_requests = InfoRequest.where(:prominence => 'requester_only')

    hidden_incoming = InfoRequest.joins(:incoming_messages).
      where(:incoming_messages => {:prominence => 'hidden'}).uniq
    requester_only_incoming = InfoRequest.joins(:incoming_messages).
      where(:incoming_messages => {:prominence => 'requester_only'}).uniq

    hidden_outgoing = InfoRequest.joins(:outgoing_messages).
      where(:outgoing_messages => {:prominence => 'hidden'}).uniq
    requester_only_outgoing = InfoRequest.joins(:outgoing_messages).
      where(:outgoing_messages => {:prominence => 'requester_only'}).uniq

    [['Hidden requests', hidden_requests],
     ['Requester-only requests', requester_only_requests],
     ['Requests with hidden incoming messages', hidden_incoming],
     ['Requests with requester-only incoming messages', requester_only_incoming],
     ['Requests with hidden outgoing messages', hidden_outgoing],
     ['Requests with requester-only outgoing messages', requester_only_outgoing]].each do |title, list|
      unless list.empty?
        puts "#{title}\n"
        list.each do |request|
          puts "#{admin_request_url(request, :host => AlaveteliConfiguration::domain)}\n"
        end
      end
    end
  end
end
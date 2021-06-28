namespace :cleanup do

  desc 'Clean up all message redelivery and destroy actions from the holding pen to make admin actions there faster'
  task :holding_pen => :environment do
    dryrun = ENV['DRYRUN'] != '0' if ENV['DRYRUN']
    if dryrun
      $stderr.puts "This is a dryrun - nothing will be deleted"
    end
    holding_pen = InfoRequest.holding_pen_request
    holding_pen.info_request_events.
      where(:event_type => %w(redeliver_incoming destroy_incoming)).
        find_each do |event|
      $stderr.puts event.inspect if verbose or dryrun
      if not dryrun
        event.destroy
      end
    end
  end

  desc 'Interactively cleanup spam user users'
  task :spam_users => :environment do
    spam_scorer = UserSpamScorer.new

    results = {}
    User.includes(:info_requests).
      where("info_requests.user_id IS NULL
             AND about_me LIKE '%http%'
             AND ban_text = ''
             AND confirmed_not_spam = ?", false).
        order("users.created_at DESC").find_each do |user|
          results[user.id] = spam_scorer.score(user)
    end

    results.sort_by(&:last).reverse.each do |user_id, spam_score|
      user = User.find(user_id)

      user.with_lock do
        display_user(user, spam_score)

        begin
          puts "Is this a spam account? [(Y)es/(n)o/(s)kip]"
          input = $stdin.gets.strip
        end until %w(Y n s).include?(input)

        case input
        when 'Y'
          puts "Banning #{ user.id }\n\n"
          user.update!(:ban_text => 'Banned for spamming')
        when 'n'
          puts "Marking #{ user.id } as genuine\n\n"
          user.update!(:confirmed_not_spam => true)
        when 's'
          puts "Skipping #{ user.id }\n\n"
        end
      end
    end
  end

  desc 'Reindex banned users'
  task :reindex_banned_users => :environment do
    User.banned.find_each do |user|
      user.xapian_mark_needs_index
    end
  end

  desc 'Export of last 2 days of requests to search for spam'
  task :spam_requests => :environment do
    str = CSV.generate do |csv|
      # Make headers
      csv << [
        'info_request_id',
        'info_request_title',
        'user_id',
        'public_body_id',
        'public_body_name',
        'public_body_request_email',
        'created_at',
      ]

      # Add rows
      InfoRequest.where(:created_at => [2.days.ago..Time.zone.now]).find_each do |request|
        csv << [
         request.id,
         request.title,
         request.user_id,
         request.public_body_id,
         request.public_body.name,
         request.public_body.request_email,
         request.created_at.to_s,
        ]
      end
    end

    puts str
  end

end

def display_user(user, spam_score)
  puts "ID: #{user.id}"
  puts "Created: #{user.created_at}"
  puts "Name: #{user.name}"
  puts "Email: #{user.email}"
  puts "Link(s): #{extract_links(user.about_me).join(", ")}"
  puts "Profile: #{user.about_me}"
  puts "Spam Score: #{spam_score}"
end

def extract_links(text)
  text.scan(/https?:\/\/[^\s]+/)
end

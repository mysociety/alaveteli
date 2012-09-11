namespace :temp do

    desc 'Populate the request_classifications table from info_request_events'
    task :populate_request_classifications => :environment do
        InfoRequestEvent.find_each(:conditions => ["event_type = 'status_update'"]) do |classification|
            RequestClassification.create!(:created_at => classification.created_at,
                                          :user_id => classification.params[:user_id],
                                          :info_request_event_id => classification.id)
        end
    end

    desc "Remove plaintext passwords from post_redirect params"
    task :remove_post_redirect_passwords => :environment do
        PostRedirect.find_each(:conditions => ['post_params_yaml is not null']) do |post_redirect|
              if post_redirect.post_params && post_redirect.post_params[:signchangeemail] && post_redirect.post_params[:signchangeemail][:password]
                params = post_redirect.post_params
                params[:signchangeemail].delete(:password)
                post_redirect.post_params = params
                post_redirect.save!
              end
        end
    end

    desc 'Remove file caches for requests that are not publicly visible or have been destroyed'
    task :remove_obsolete_info_request_caches => :environment do
        dryrun = ENV['DRYRUN'] == '0' ? false : true
        verbose = ENV['VERBOSE'] == '0' ? false : true
        if dryrun
            puts "Running in dryrun mode"
        end
        request_cache_path = File.join(Rails.root, 'cache', 'views', 'request', '*', '*')
        Dir.glob(request_cache_path) do |request_subdir|
            info_request_id = File.basename(request_subdir)
            puts "Looking for InfoRequest with id #{info_request_id}" if verbose
            begin
                info_request = InfoRequest.find(info_request_id)
                puts "Got InfoRequest #{info_request_id}" if verbose
                if ! info_request.all_can_view?
                    puts "Deleting cache at #{request_subdir} for hidden/requester_only InfoRequest #{info_request_id}"
                    if ! dryrun
                        FileUtils.rm_rf(request_subdir)
                    end
                end
            rescue ActiveRecord::RecordNotFound
                puts "Deleting cache at #{request_subdir} for deleted InfoRequest #{info_request_id}"
                if ! dryrun
                    FileUtils.rm_rf(request_subdir)
                end
            end
        end
    end

end

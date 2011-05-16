namespace :temp do

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

end

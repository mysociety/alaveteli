namespace :temp do
  
  desc 'Debug regexp warning in remove_lotus_quoting-method'
  task :debug_regexp_warning => [:environment] do 
    messages = IncomingMessage.find(:all)
    messages.each do |message|
      puts message.info_request.title
      message.get_body_for_quoting
      sleep 2
    end
  end
  
end
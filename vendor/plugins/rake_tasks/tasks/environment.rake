#
# Thanks to Chris for this handy task (http://errtheblog.com/post/33)
#
%w[development test production].each do |env|
  desc "Runs the following task in the #{env} environment" 
  task env do
    RAILS_ENV = ENV['RAILS_ENV'] = env
  end
end
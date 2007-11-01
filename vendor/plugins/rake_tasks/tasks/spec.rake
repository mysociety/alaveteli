namespace :spec do
  unless defined?(RAILS_ROOT)
    root_path = File.join(File.dirname(__FILE__), '..')
    unless RUBY_PLATFORM =~ /mswin32/
      require 'pathname'
      root_path = Pathname.new(root_path).cleanpath(true).to_s
    end
    RAILS_ROOT = root_path
  end

  require "#{RAILS_ROOT}/config/environment"

  PROJ_DIR = "#{RAILS_ROOT}/app/"
  
  def view_ext
    if ActionView::Base.const_defined?('DEFAULT_TEMPLATE_HANDLER_PREFERENCE') &&
       ActionView::Base::DEFAULT_TEMPLATE_HANDLER_PREFERENCE.include?(:erb) then
      return ".html.erb"
    else
      return ".rhtml"
    end
  end
  
  def find_untested_ruby_files
    files = {}
    `find #{PROJ_DIR} -name '*.rb'`.split(/\n/).each do |file|
      spec_file = file.sub('/app/', '/spec/').sub('.rb', '_spec.rb')
      dir_type = File.dirname(file).split("/").last
      next if dir_type == "helpers"
      type = (dir_type == "models" ? "model" : "controller")
      File.exists?(spec_file) ? next : files[spec_file] = type
    end
    files
  end

  def find_untested_view_files
    files = {}
    `find #{PROJ_DIR} -name '*#{view_ext}'`.split(/\n/).each do |file|
      spec_file = file.sub('/app/', '/spec/').sub(view_ext, "#{view_ext}_spec.rb")
      type = File.dirname(file).split("/").last
      File.exists?(spec_file) ? next : files[spec_file] = type
    end
    files
  end

  desc "Check files in the app directory for corresponding test files in the spec directory."
  task :check do
    # XXX Don't check views, as we use controllers for view tests. Francis.
    files = find_untested_ruby_files #.merge(find_untested_view_files)
    unless files.empty?
      puts "Missing test files:"
      files.each {|file, type|  puts "  #{file}"}
      puts
      puts "Run the following command(s) to create the missing files:"
      puts "  rake spec:sync"
    end
  end

  desc "Check for missing test files in the spec directory and create them if they don't exist."
  task :sync do
    # Check if an application_controller file exists... hopefully it does not.
    has_application_controller = File.exists?("#{PROJ_DIR}/controllers/application_controller.rb")
    
    files = find_untested_ruby_files
    unless files.empty?
      files.each do |file, type|
        # Get rid of the _spec and file extension
        name = File.basename(file).sub("_spec.rb", "").sub(/(_controller|_helper)/, "")

        has_controller = has_helper = false
        if type == "controller"
          has_controller = File.exists?("#{PROJ_DIR}/controllers/#{name}_controller.rb")
          has_helper = File.exists?("#{PROJ_DIR}/helpers/#{name}_helper.rb")
        end

        options = "--skip"
        options += " --skip-migration" if type == "model"
        puts `script/generate rspec_#{type} #{options} #{name} | grep create`
        
        unless has_controller
          FileUtils.rm "#{PROJ_DIR}/controllers/#{name}_controller.rb" if File.exists?("#{PROJ_DIR}/controllers/#{name}_controller.rb")
          FileUtils.rm "#{PROJ_DIR}/../spec/controllers/#{name}_controller_spec.rb" if File.exists?("#{PROJ_DIR}/../spec/controllers/#{name}_controller_spec.rb")
        end

        unless has_helper
          FileUtils.rm "#{PROJ_DIR}/helpers/#{name}_helper.rb" if File.exists?("#{PROJ_DIR}/helpers/#{name}_helper.rb")
          FileUtils.rm "#{PROJ_DIR}/../spec/helpers/#{name}_helper_spec.rb" if File.exists?("#{PROJ_DIR}/../spec/helpers/#{name}_helper_spec.rb")
        end        
      end
    end

    files = find_untested_view_files
    unless files.empty?
      action_list = {}
      files.each do |file, controller|
        action = File.basename(file)[0..-9].sub(view_ext, "")

        if action_list[controller].blank?
          action_list[controller] = action
        else
          action_list[controller] = "#{action_list[controller]} #{action}"
        end
      end
      
      action_list.each do |controller, actions|
        next if actions.blank?

        has_controller = File.exists?("#{PROJ_DIR}/controllers/#{controller}_controller.rb")
        has_helper = File.exists?("#{PROJ_DIR}/helpers/#{controller}_helper.rb")

        puts `script/generate rspec_controller --skip #{controller} #{actions} | grep create`
        
        unless has_controller
          FileUtils.rm "#{PROJ_DIR}/controllers/#{controller}_controller.rb"
          FileUtils.rm "#{PROJ_DIR}/../spec/controllers/#{controller}_controller_spec.rb"
        end

        unless has_helper
          FileUtils.rm "#{PROJ_DIR}/helpers/#{controller}_helper.rb"
          FileUtils.rm "#{PROJ_DIR}/../spec/helpers/#{controller}_helper_spec.rb"
        end        
      end
    end
  end
end

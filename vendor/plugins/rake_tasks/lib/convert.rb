module Convert
  # allows different paths for searching to be set
  def self.view_path=(path)
    @@view_path = path
  end
  
  def self.view_path
    @@view_path ||= RAILS_ROOT+'/app/views/'
  end
  
  # Given a file extension will search for all files recursively in a directory
  # and move the files using the move command or subversion move command
  #
  # Example:
  #
  #   Convert::Mover.find(:rhtml).each do |rhtml|
  #     rhtml.move :erb, :scm => :svn
  #   end
  #
  # This will find all .rhtml files within the views directory and move each file
  # to a erb extension using subversion
  class Mover

    def self.find(file_extension)
      files =  File.join(Convert::view_path,'**', "*.#{file_extension}")
      Dir.glob(files).collect do |path|
        self.new(path, file_extension)
      end
    end
    
    def initialize(file_path, file_extension)
      @file_path = file_path
      @file_extension = file_extension
    end
    
    def move_command(move_to_extension, options = {})
      original_path = File.expand_path(@file_path)
      new_path   = original_path.gsub(".#{@file_extension}", ".#{move_to_extension}")
      
      "#{options[:scm]} mv #{original_path} #{new_path}".lstrip 
    end
    
    def move(move_to_extension, options = {})
      system self.move_command(move_to_extension, options)
    end
  end
end
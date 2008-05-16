class ActsAsXapianGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate',
        :migration_file_name => "create_acts_as_xapian"
    end
  end
  
  protected
    def banner
      "Usage: #{$0} acts_as_xapian"
    end
end

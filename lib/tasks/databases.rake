#binding.pry
#require 'active_record/railties/databases'
load 'active_record/railties/databases.rake'

Rake::Task['db:structure:dump'].clear

db_namespace = namespace :db do
  def drop_database(config)
    case config['adapter']
    when /mysql/
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.drop_database config['database']
    when /sqlite/
      require 'pathname'
      path = Pathname.new(config['database'])
      file = path.absolute? ? path.to_s : File.join(Rails.root, path)

      FileUtils.rm(file)
    when /postgresql/
      ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
      ActiveRecord::Base.connection.drop_database config['database']
    end
  end

  def drop_database_and_rescue(config)
    begin
      drop_database(config)
    rescue Exception => e
      $stderr.puts "Couldn't drop #{config['database']} : #{e.inspect}"
    end
  end

  def configs_for_environment
    environments = [Rails.env]
    environments << 'test' if Rails.env.development?
    ActiveRecord::Base.configurations.values_at(*environments).compact.reject { |config| config['database'].blank? }
  end

  def session_table_name
    ActiveRecord::SessionStore::Session.table_name
  end

  def set_firebird_env(config)
    ENV['ISC_USER']     = config['username'].to_s if config['username']
    ENV['ISC_PASSWORD'] = config['password'].to_s if config['password']
  end

  def firebird_db_string(config)
    FireRuby::Database.db_string_for(config.symbolize_keys)
  end

  def set_psql_env(config)
    ENV['PGHOST']     = config['host']          if config['host']
    ENV['PGPORT']     = config['port'].to_s     if config['port']
    ENV['PGPASSWORD'] = config['password'].to_s if config['password']
    ENV['PGUSER']     = config['username'].to_s if config['username']
  end

  def database_url_config
    @database_url_config ||=
        ActiveRecord::Base::ConnectionSpecification::Resolver.new(ENV["DATABASE_URL"], {}).spec.config.stringify_keys
  end

  def current_config(options = {})
    options = { :env => Rails.env }.merge! options

    if options[:config]
      @current_config = options[:config]
    else
      @current_config ||= if ENV['DATABASE_URL']
                            database_url_config
                          else
                            ActiveRecord::Base.configurations[options[:env]]
                          end
    end
  end

  namespace :structure do
    desc 'Dump the database structure to db/structure.sql. Specify another file with DB_STRUCTURE=db/my_structure.sql'
    task :dump => [:environment, :load_config] do
      puts ">>>>>>>>>>>> MONKEYPATCHED db:structure:dump"

      config = current_config
      filename = ENV['DB_STRUCTURE'] || File.join(Rails.root, "db", "structure.sql")
      case config['adapter']
      when /mysql/, 'oci', 'oracle'
        ActiveRecord::Base.establish_connection(config)
        File.open(filename, "w:utf-8") { |f| f << ActiveRecord::Base.connection.structure_dump }
      when /postgresql/
        set_psql_env(config)
        search_path = config['schema_search_path']
        unless search_path.blank?
          search_path = search_path.split(",").map{|search_path_part| "--schema=#{Shellwords.escape(search_path_part.strip)}" }.join(" ")
        end
        `pg_dump -s -x -O -f #{Shellwords.escape(filename)} #{search_path} #{Shellwords.escape(config['database'])}`
        raise 'Error dumping database' if $?.exitstatus == 1
        File.open(filename, "a") { |f| f << "SET search_path TO #{ActiveRecord::Base.connection.schema_search_path};\n\n" }
      when /sqlite/
        dbfile = config['database']
        `sqlite3 #{dbfile} .schema > #{filename}`
      when 'sqlserver'
        `smoscript -s #{config['host']} -d #{config['database']} -u #{config['username']} -p #{config['password']} -f #{filename} -A -U`
      when "firebird"
        set_firebird_env(config)
        db_string = firebird_db_string(config)
        sh "isql -a #{db_string} > #{filename}"
      else
        raise "Task not supported by '#{config['adapter']}'"
      end

      if ActiveRecord::Base.connection.supports_migrations?
        File.open(filename, "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
      end
      db_namespace['structure:dump'].reenable
    end
  end
end

require File.join(File.dirname(__FILE__), 'usage')
namespace :config_files do

  include Usage

  class ExampleERBRenderer
    def initialize(file, **variables)
      @template = ERB.new(File.read(file))
      @variables = variables
    end

    def lines
      @template.result(binding).split(/\r?\n/)
    end

    def method_missing(variable, *_args)
      @variables.fetch(variable) do
        raise "Unhandled variable in example file: #{variable}"
      end
    end
  end

  def convert_erb(file, **replacements)
    ExampleERBRenderer.new(file, **replacements).lines
  end

  def daemons(only_active = false)
    daemons = %w[alert-tracks send-notifications]
    if AlaveteliConfiguration.production_mailer_retriever_method == 'pop' ||
       !only_active
      daemons << 'poll-for-incoming'
    end
    daemons
  end

  desc 'Return list of daemons to install based on the settings defined
        in general.yml'
  task active_daemons: :environment do
    puts daemons(true)
  end

  desc 'Return list of all daemons the application defines'
  task all_daemons: :environment do
    puts daemons
  end

  desc 'Return the value of a config param'
  task get_config_value: :environment do
    example = 'rake config_files:get_config_value ' \
              'KEY=PRODUCTION_MAILER_RETRIEVER_METHOD'
    check_for_env_vars(['KEY'], example)
    key = ENV['KEY']
    if AlaveteliConfiguration::DEFAULTS.key?(key.to_sym)
      puts MySociety::Config.
        get(key, AlaveteliConfiguration::DEFAULTS[key.to_sym])
    end
  end

  desc 'Convert wrapper example in config to a form suitable for running mail handling scripts with rbenv'
  task convert_wrapper: :environment do
    example = 'rake config_files:convert_wrapper DEPLOY_USER=deploy SCRIPT_FILE=config/run-with-rbenv-path.example'
    check_for_env_vars(%w[DEPLOY_USER SCRIPT_FILE], example)

    replacements = {
      user: ENV['DEPLOY_USER'],
    }

    # Generate the template for potential further processing
    convert_erb(ENV['SCRIPT_FILE'], **replacements).each do |line|
      puts line
    end
  end

  desc 'Convert Debian example init script in config to a form suitable for installing in /etc/init.d'
  task convert_init_script: :environment do
    example = 'rake config_files:convert_init_script ' \
              'DEPLOY_USER=deploy ' \
              'VHOST_DIR=/dir/above/alaveteli ' \
              'VCSPATH=alaveteli ' \
              'SITE=alaveteli ' \
              'SCRIPT_FILE=config/alert-tracks-debian.example ' \
              'RUBY_VERSION=3.0.4 ' \
              'USE_RBENV=false '
    check_for_env_vars(%w[DEPLOY_USER VHOST_DIR SCRIPT_FILE], example)

    replacements = {
      user: ENV['DEPLOY_USER'],
      vhost_dir: ENV['VHOST_DIR'],
      vcspath: ENV.fetch('VCSPATH') { 'alaveteli' },
      site: ENV.fetch('SITE') { 'foi' },
      cpus: ENV.fetch('CPUS') { '1' },
      rails_env: ENV.fetch('RAILS_ENV') { 'development' },
      ruby_version: ENV.fetch('RUBY_VERSION') { '' },
      use_rbenv?: ENV['USE_RBENV'] == 'true'
    }

    # Use the filename for the $daemon_name ugly variable
    daemon_name = File.basename(ENV['SCRIPT_FILE'], '-debian.example')
    replacements.update(daemon_name: "#{ replacements[:site] }-#{ daemon_name }")

    # Generate the template for potential further processing
    converted = convert_erb(ENV['SCRIPT_FILE'], **replacements)

    # uncomment RAILS_ENV in to the generated template if its not set by the
    # hard coded config file
    unless File.exist?("#{ Rails.root }/config/rails_env.rb")
      converted.each do |line|
        line.gsub!(/^#\s*RAILS_ENV=/, "RAILS_ENV=")
        line.gsub!(/^#\s*export RAILS_ENV/, "export RAILS_ENV")
      end
    end

    converted.each do |line|
      puts line
    end
  end

  desc 'Convert Debian example crontab file in config to a form suitable for installing in /etc/cron.d'
  task convert_crontab: :environment do
    example = 'rake config_files:convert_crontab ' \
              'DEPLOY_USER=deploy ' \
              'VHOST_DIR=/dir/above/alaveteli VCSPATH=alaveteli ' \
              'SITE=alaveteli CRONTAB=config/crontab-example ' \
              'MAILTO=cron-alaveteli@example.org ' \
              'RUBY_VERSION=3.0.4 '
              'USE_RBENV=false '
    check_for_env_vars(%w[DEPLOY_USER VHOST_DIR VCSPATH SITE CRONTAB], example)
    replacements = {
      user: ENV['DEPLOY_USER'],
      vhost_dir: ENV['VHOST_DIR'],
      vcspath: ENV['VCSPATH'],
      site: ENV['SITE'],
      mailto: ENV.fetch('MAILTO') { "#{ ENV['DEPLOY_USER'] }@localhost" },
      ruby_version: ENV.fetch('RUBY_VERSION') { '' },
      use_rbenv?: ENV['USE_RBENV'] == 'true'
    }

    lines = []
    convert_erb(ENV['CRONTAB'], **replacements).each do |line|
      lines << line
    end

    lines.each do |line|
      puts line
    end
  end

  desc 'Convert miscellaneous example scripts. This does not check for required environment variables for the script, so please check the script file itself.'
  task convert_script: :environment do
    example = 'rake config_files:convert_script SCRIPT_FILE=config/run-with-rbenv-path.example'
    check_for_env_vars(['SCRIPT_FILE'], example)

    replacements = {
      user: ENV.fetch('DEPLOY_USER') { 'alaveteli' },
      vhost_dir: ENV.fetch('VHOST_DIR') { '/var/www/alaveteli' },
      vcspath: ENV.fetch('VCSPATH') { 'alaveteli' },
      site: ENV.fetch('SITE') { 'foi' },
      cpus: ENV.fetch('CPUS') { '1' },
      rails_env: ENV.fetch('RAILS_ENV') { 'development' }
    }

    # Generate the template for potential further processing
    converted = convert_erb(ENV['SCRIPT_FILE'], **replacements)

    # uncomment RAILS_ENV in to the generated template if its not set by the
    # hard coded config file
    unless File.exist?("#{ Rails.root }/config/rails_env.rb")
      converted.each do |line|
        line.gsub!(/^#\s*RAILS_ENV=/, "RAILS_ENV=")
        line.gsub!(/^#\s*export RAILS_ENV/, "export RAILS_ENV")
      end
    end

    converted.each do |line|
      puts line
    end
  end

  desc 'Set reject_incoming_at_mta on old requests that are rejecting incoming mail'
  task set_reject_incoming_at_mta: :environment do
    example = 'rake config_files:set_reject_incoming_at_mta REJECTED_THRESHOLD=5 AGE_IN_MONTHS=12'
    check_for_env_vars(%w[REJECTED_THRESHOLD AGE_IN_MONTHS], example)
    dryrun = ENV['DRYRUN'] != '0'
    STDERR.puts "Only a dry run; info_requests will not be updated" if dryrun
    options = {rejection_threshold: ENV['REJECTED_THRESHOLD'],
               age_in_months: ENV['AGE_IN_MONTHS'],
               dryrun: dryrun}

    updated_count = InfoRequest.reject_incoming_at_mta(options) do |ids|
      puts "Info Request\tRejected incoming count\tLast updated"
      ids.each do |id|
        info_request = InfoRequest.find(id)
        puts "#{info_request.id}\t#{info_request.rejected_incoming_count}\t#{info_request.updated_at}"
      end
    end
    puts "Updated #{updated_count} info requests"
  end

  desc 'Set reject_incoming_at_mta on a list of requests identified by ' \
       'request address'
  task set_reject_incoming_at_mta_from_list: :environment do
    example = 'rake temp:set_reject_incoming_at_mta_from_list ' \
              'FILE=/tmp/rejection_list.txt'

    check_for_env_vars(['FILE'], example)

    File.read(ENV['FILE']).each_line do |line|
      info_request = InfoRequest.find_by_incoming_email(line.strip)
      info_request.reject_incoming_at_mta = true
      info_request.save!
    end
  end

  desc 'Unset reject_incoming_at_mta on a request'
  task unset_reject_incoming_at_mta: :environment do
    example = 'rake config_files:unset_reject_incoming_at_mta REQUEST_ID=4'
    check_for_env_vars(['REQUEST_ID'], example)
    info_request = InfoRequest.find(ENV['REQUEST_ID'])
    if info_request.reject_incoming_at_mta
      info_request.reject_incoming_at_mta = false
      info_request.allow_new_responses_from = 'authority_only'
      info_request.save!
      puts "reject_incoming_at_mta set to false for InfoRequest #{ENV['REQUEST_ID']}"
    else
      puts "Warning: reject_incoming_at_mta already false for " \
           "InfoRequest #{ENV['REQUEST_ID']}"
    end
  end

  desc 'Produce a list of email addresses for which the MTA should reject messages at RCPT time'
  task generate_mta_rejection_list: :environment do
    example = 'rake config_files:generate_mta_rejection_list MTA=(exim|postfix)'
    check_for_env_vars(['MTA'], example)
    mta = ENV['MTA'].downcase
    unless %w[postfix exim].include? mta
      puts "Error: Unrecognised MTA"
      exit 1
    end
    InfoRequest.where(reject_incoming_at_mta: true).each do |info_request|
      if mta == 'postfix'
        puts "#{info_request.incoming_email} REJECT"
      else
        puts info_request.incoming_email
      end
    end
  end
end

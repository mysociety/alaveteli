require File.join(File.dirname(__FILE__), 'usage')
namespace :config_files do

  include Usage

  class ExampleERBRenderer
    def initialize(file, **variables)
      @template = ERB.new(File.read(file), trim_mode: '-')
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
    puts ExampleERBRenderer.new(file, **replacements).lines
  end

  def default_replacements
    opts = {
      cpus: ENV.fetch('CPUS') { '1' },
      mailto: ENV.fetch('MAILTO') { "#{ ENV['DEPLOY_USER'] }@localhost" },
      rails_env: ENV.fetch('RAILS_ENV') { 'development' },
      ruby_version: ENV.fetch('RUBY_VERSION') { '3.2.2' },
      site: ENV.fetch('SITE') { 'foi' },
      user: ENV.fetch('DEPLOY_USER') { 'alaveteli' },
      vcspath: ENV.fetch('VCSPATH') { 'alaveteli' },
      vhost_dir: ENV.fetch('VHOST_DIR') { '/var/www/alaveteli' },
      use_rbenv?: ENV.fetch('USE_RBENV', 'false') == 'true',
      rails_env_defined?: ENV['RAILS_ENV_DEFINED'] == 'true'
    }

    if opts[:use_rbenv?]
      rbenv_root = "/home/#{opts[:user]}/.rbenv"
      opts[:ruby_path] = "#{rbenv_root}/bin:#{rbenv_root}/shims"
    else
      opts[:ruby_path] = "/home/#{opts[:user]}/.gem/ruby/#{opts[:ruby_version]}/bin"
    end

    opts
  end

  def daemons
    [
      {
        path: '/etc/init.d',
        name: 'thin',
        template: 'config/sysvinit-thin.example',
        condition: -> { ENV['RAILS_ENV'] == 'production' }
      },
      {
        path: '/etc/systemd/system',
        name: 'sidekiq.service',
        template: 'config/sidekiq.service.example'
      },
      {
        path: '/etc/systemd/system',
        name: 'alert-tracks.service',
        template: 'config/alert-tracks.service.example'
      },
      {
        path: '/etc/systemd/system',
        name: 'send-notifications.service',
        template: 'config/send-notifications.service.example'
      },
      {
        path: '/etc/systemd/system',
        name: 'poll-for-incoming',
        template: 'config/poll-for-incoming.service.example',
        condition: -> do
          AlaveteliConfiguration.production_mailer_retriever_method == 'pop'
        end
      }
    ]
  end

  desc 'Return list of daemons to install based on the settings defined
        in general.yml for a given path'
  task active_daemons: :environment do
    example = 'rake config_files:active_daemons PATH=/etc/init.d'
    check_for_env_vars(['PATH'], example)

    puts daemons.
      select { |d| d[:path] == ENV['PATH'] }.
      select { |d| d.fetch(:condition, -> { true }).call }.
      map { |d| d[:name] }
  end

  desc 'Return list of all daemons the application defines for a given path'
  task all_daemons: :environment do
    example = 'rake config_files:all_daemons PATH=/etc/init.d SITE=alaveteli'
    check_for_env_vars(['PATH', 'SITE'], example)

    seporator = '-' if ENV['PATH'] == '/etc/init.d'
    seporator = '.' if ENV['PATH'] == '/etc/systemd/system'

    base = "#{ENV['SITE']}#{seporator}"
    glob = File.join("#{base}*")
    puts Dir.glob(glob, base: ENV['PATH']).map { _1.sub(base, '') }
  end

  desc 'Convert wrapper example in config to a form suitable for running mail handling scripts with rbenv'
  task convert_wrapper: :environment do
    example = 'rake config_files:convert_wrapper DEPLOY_USER=deploy SCRIPT_FILE=config/run-with-rbenv-path.example'
    check_for_env_vars(%w[DEPLOY_USER SCRIPT_FILE], example)

    convert_erb(ENV['SCRIPT_FILE'], **default_replacements)
  end

  desc 'Convert Debian example init script in config to a form suitable for installing in /etc/init.d'
  task convert_init_script: :environment do
    example = 'rake config_files:convert_init_script ' \
              'DEPLOY_USER=deploy ' \
              'VHOST_DIR=/dir/above/alaveteli ' \
              'VCSPATH=alaveteli ' \
              'SITE=alaveteli ' \
              'SCRIPT_FILE=config/sysvinit-thin.example ' \
              'RUBY_VERSION=3.2.2 ' \
              'USE_RBENV=false '
    check_for_env_vars(%w[DEPLOY_USER VHOST_DIR SCRIPT_FILE], example)

    daemon_name = ENV.fetch('DAEMON_NAME') do
      File.basename(ENV['SCRIPT_FILE'], '-debian.example')
    end

    replacements = default_replacements.merge(
      daemon_name: "#{default_replacements[:site]}-#{daemon_name}"
    )

    convert_erb(ENV['SCRIPT_FILE'], **replacements)
  end

  desc 'Convert example daemon in config to a form suitable for installing ' \
       'on a server'
  task convert_daemon: :environment do
    example = 'rake config_files:convert_daemon ' \
              'DEPLOY_USER=deploy ' \
              'VHOST_DIR=/dir/above/alaveteli ' \
              'VCSPATH=alaveteli ' \
              'SITE=alaveteli ' \
              'DAEMON=alert-tracks.service ' \
              'RUBY_VERSION=3.2.2 ' \
              'USE_RBENV=false '
    check_for_env_vars(%w[DEPLOY_USER VHOST_DIR DAEMON], example)

    daemon = daemons.find { |d| d[:name] == ENV['DAEMON'] }
    raise 'Unknown daemon' unless daemon

    ENV['SCRIPT_FILE'] = daemon[:template]
    ENV['DAEMON_NAME'] = daemon[:name].sub(/\.service$/, '')

    Rake::Task['config_files:convert_init_script'].invoke
  end

  desc 'Convert Debian example crontab file in config to a form suitable for installing in /etc/cron.d'
  task convert_crontab: :environment do
    example = 'rake config_files:convert_crontab ' \
              'DEPLOY_USER=deploy ' \
              'VHOST_DIR=/dir/above/alaveteli VCSPATH=alaveteli ' \
              'SITE=alaveteli CRONTAB=config/crontab-example ' \
              'MAILTO=cron-alaveteli@example.org ' \
              'RUBY_VERSION=3.2.2 ' \
              'USE_RBENV=false '
    check_for_env_vars(%w[DEPLOY_USER VHOST_DIR VCSPATH SITE CRONTAB], example)
    convert_erb(ENV['CRONTAB'], **default_replacements)
  end

  desc 'Convert miscellaneous example scripts. This does not check for required environment variables for the script, so please check the script file itself.'
  task convert_script: :environment do
    example = 'rake config_files:convert_script SCRIPT_FILE=config/run-with-rbenv-path.example'
    check_for_env_vars(['SCRIPT_FILE'], example)
    convert_erb(ENV['SCRIPT_FILE'], **default_replacements)
  end

  desc 'Set reject_incoming_at_mta on old requests that are rejecting incoming mail'
  task set_reject_incoming_at_mta: :environment do
    example = 'rake config_files:set_reject_incoming_at_mta REJECTED_THRESHOLD=5 AGE_IN_MONTHS=12'
    check_for_env_vars(%w[REJECTED_THRESHOLD AGE_IN_MONTHS], example)
    dryrun = ENV['DRYRUN'] != '0'
    STDERR.puts "Only a dry run; info_requests will not be updated" if dryrun
    options = { rejection_threshold: ENV['REJECTED_THRESHOLD'],
               age_in_months: ENV['AGE_IN_MONTHS'],
               dryrun: dryrun }

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
    example = 'rake config_files:set_reject_incoming_at_mta_from_list ' \
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

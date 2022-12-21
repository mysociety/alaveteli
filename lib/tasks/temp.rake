namespace :temp do
  desc 'Convert old Syck YAML to Psych YAML'
  task convert_syck_to_psych_yaml: :environment do
    require 'syck'

    # requiring Syck redefines the YAML constant, we need to reset this back to
    # Psych otherwise we can't load the InfoRequestEvent instances.
    Object.send(:remove_const, :YAML)
    YAML = Psych

    scope = InfoRequestEvent.where(params: nil)
    count = scope.count

    scope.find_each.with_index do |event, index|
      begin
        Psych.parse(event.params_yaml)
      rescue Psych::SyntaxError
        yaml = Syck.load(event.params_yaml)

        event.no_xapian_reindex = true
        event.update(params_yaml: Psych.dump(yaml))
      end

      erase_line
      print "Converted InfoRequestEvent#param_yaml #{index + 1}/#{count}"
    end

    erase_line
    puts "Converted InfoRequestEvent#params_yaml completed."
  end

  desc "Fix old objects stored in YAML which can't be decoded"
  task fix_old_objects_in_yaml: :environment do
    scope = InfoRequestEvent.where(params: nil)
    count = scope.count

    scope.find_each.with_index do |event, index|
      yaml = Psych.dump(
        event.params.inject({}) do |params, (key, value)|
          begin
            # each param value needs to be able to converted into YAML but this
            # can blow up for old Ruby objects previously stored as newer Rails
            # can't correctly decode values generated older versions
            value.to_yaml if value.is_a?(ApplicationRecord)
          rescue NoMethodError
            # reload object from DB store YAML value doesn't need to be decoded
            value = value.reload
          end
          params[key] = value
          params
        end
      )

      event.no_xapian_reindex = true
      event.update(params_yaml: yaml)

      erase_line
      print "Fixed InfoRequestEvent#param_yaml #{index + 1}/#{count}"
    end

    erase_line
    puts "Fixed InfoRequestEvent#params_yaml completed."
  end

  desc 'Sanitise and populate events params json column from yaml'
  task sanitise_and_populate_events_params_json: :environment do
    scope = InfoRequestEvent.where(params: nil)
    count = scope.count

    scope.find_each.with_index do |event, index|
      event.no_xapian_reindex = true
      event.update(params: event.params)

      erase_line
      print "Populated InfoRequestEvent#param #{index + 1}/#{count}"
    end

    erase_line
    puts "Populated InfoRequestEvent#params completed."
  end

  desc 'Migrate PublicBody notes into Note model'
  task migrate_public_body_notes: :environment do
    scope = PublicBody.where.not(notes: nil)
    count = scope.count

    scope.with_translations.find_each.with_index do |body, index|
      PublicBody.transaction do
        body.legacy_note&.save
        body.translations.update(notes: nil)
      end

      erase_line
      print "Migrated PublicBody#notes #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrated PublicBody#notes completed."
  end

  desc 'Populate incoming message from email'
  task populate_incoming_message_from_email: :environment do
    scope = IncomingMessage.where(from_email: nil)
    count = scope.count

    scope.includes(:raw_email).find_each.with_index do |message, index|
      message.update_columns(from_email: message.raw_email.from_email || '')

      erase_line
      print "Populated IncomingMessage#from_email #{index + 1}/#{count}"
    end

    erase_line
    puts "Populated IncomingMessage#from_email completed."
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end

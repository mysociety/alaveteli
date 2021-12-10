#!/usr/bin/env ruby

require 'optparse'

options = { tmp: true }
parser = OptionParser.new do |opts|
  opts.on(
    '-uID', '--user=ID',
    'User ID to redact from incoming_messages'
  ) do |arg|
    options[:user_id] = arg
  end
  opts.on(
    '-mID', '--message=ID',
    'Limit to an incoming message with ID'
  ) do |arg|
    options[:incoming_message_id] = arg
  end
  opts.on(
    '-r', '--replace',
    'Replace redacted emails on disk'
  ) do
    options[:tmp] = false
  end
end
parser.parse!

require_relative File.join('..', 'config', 'environment')

# PATCH: Add incoming_messages association to User class
class User
  has_many :incoming_messages, through: :info_requests
end

# PATCH: Remove text masks for emails addresses and mobile phone numbers
module AlaveteliTextMasker
  def apply_binary_masks(text, options = {})
    # Keep original size, so can check haven't resized it
    orig_size = text.bytesize
    text = text.dup

    # Replace censor items
    censor_rules = options[:censor_rules] || []
    text = censor_rules.reduce(text) { |t, rule| rule.apply_to_binary(t) }
    raise "internal error in apply_binary_masks" if text.bytesize != orig_size

    text
  end
end

def censor_data(data, content_type)
  @incoming_message.apply_masks(data, content_type)
end

def censor(text)
  return unless text
  @incoming_message.info_request.apply_censor_rules_to_text(text)
end

def censor_part(part)
  if part.multipart?
    part.parts.each { |nested_part| censor_part(nested_part) }

  elsif part.attachment?
    encoding = part.content_transfer_encoding
    encoder = Mail::Encodings.get_encoding(encoding)
    raise 'Unknow encoding' unless encoder

    part.body = encoder.encode(
      censor_data(part.body.decoded, part.content_type)
    )

    # TODO: censor content disposition

  else
    part.body = censor(part.body.decoded)
  end
end

include Rails.application.routes.url_helpers
default_url_options[:host] = AlaveteliConfiguration.domain

if options[:user_id] && options[:incoming_message_id]
  scope = User.find(options[:user_id]).incoming_messages.
    where(id: options[:incoming_message_id])
elsif options[:incoming_message_id]
  scope = IncomingMessage.where(id: options[:incoming_message_id])
elsif options[:user_id]
  scope = User.find(options[:user_id]).incoming_messages
else
  puts parser.help
  exit
end

puts 'WARNING: Redactions might not be perfect and if you use this script ' \
  'then you should manually check the redactions to ensure this is doing ' \
  'what you would expect.'

if options[:tmp]
  puts "Outputting redactions to tmp files. Please check these redactions " \
    "are working correctly and the emails/attachments haven't been broken."
  puts "When you are happy to proceed run with '-r' option to replace raw " \
    "emails on disk."
end

puts

scope.each do |incoming_message|
  @incoming_message = incoming_message
  @raw_email = @incoming_message.raw_email

  mail = Mail.new(@raw_email.data)

  if mail.multipart?
    mail.parts.each { |part| censor_part(part) }
  else
    mail.body = censor(mail.body.decoded)
  end

  mail.subject = censor(mail.subject)
  mail[:to]    = censor(mail[:to].to_s)
  mail[:cc]    = censor(mail[:cc].to_s)
  mail[:bcc]   = censor(mail[:bcc].to_s)

  print show_request_url(
    url_title: @incoming_message.info_request.url_title,
    anchor: "incoming-#{@incoming_message.id}"
  )

  print " cached at #{@raw_email.filepath}"

  if @raw_email.data == mail.to_s
    puts " no changes required"
    next
  end

  if options[:tmp]
    path = Rails.root.join('tmp', "redacted-#{@raw_email.id}.eml")
    File.write(path, mail.to_s)
    puts " will be replaced with #{path.relative_path_from(Rails.root)}"
  else
    FileUtils.copy(@raw_email.filepath, "#{@raw_email.filepath}.bak")
    @raw_email.data = mail.to_s
    @incoming_message.parse_raw_email!
    puts " has been updated"
    puts "Backup created at #{@raw_email.filepath}.bak"
  end
end

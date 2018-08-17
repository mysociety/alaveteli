require 'ipaddr'
require 'user_spam_scorer'

path = Rails.root.join('config/user_spam_scorer.yml')

if File.exists?(path)
  settings = YAML.load(File.read(path))['user_spam_scorer']
  settings.each do |key, value|
    case key
    when 'ip_ranges'
      value = value.map { |v| IPAddr.new(v) }
    when /_format/
      raise "UserSpamScorer: Can't load Regexp from YAML file"
    end

    UserSpamScorer.public_send("#{key}=", value)
  end
end

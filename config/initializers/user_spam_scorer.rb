require 'ipaddr'
require 'user_spam_scorer'

path = Rails.root.join('config/user_spam_scorer.yml')

if File.exist?(path)
  settings = YAML.load(
    File.read(path),
    permitted_classes: [Regexp]
  )['user_spam_scorer']
  settings.each do |key, value|
    UserSpamScorer.public_send("#{key}=", value)
  end
end

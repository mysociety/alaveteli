class UserSpamScorer
  DEFAULT_SCORE_MAPPINGS = {
    :name_is_all_lowercase? => 1,
    :name_is_one_word? => 1,
    :name_includes_non_alpha_characters? => 3,
    :name_is_garbled? => 5,
    :email_from_suspicious_domain? => 5,
    :email_from_spam_domain? => 8,
    :email_from_spam_tld? => 3,
    :name_is_spam_format? => 5,
    :about_me_includes_currency_symbol? => 2,
    :about_me_is_link_only? => 3,
    :about_me_is_spam_format? => 1,
    :about_me_includes_anchor_tag? => 1,
    :about_me_already_exists? => 4,
    :user_agent_is_suspicious? => 5,
    :ip_range_is_suspicious? => 5
  }.freeze

  DEFAULT_CURRENCY_SYMBOLS = %w(£ $ € ¥ ¢).freeze
  DEFAULT_SUSPICIOUS_DOMAINS =
    %w(mail.ru
       temp-mail.de
       tempmail.de
       shitmail.de
       yopmail.com
       yandex.com).freeze
  DEFAULT_SPAM_DOMAINS =
    %w(163.com
       7x.cz
       allemaling.com
       brmailing.com
       businessmailsystem.com
       checknowmail.com
       colde-mail.com
       consimail.com
       continumail.com
       contumail.com
       customprintingfabric.com
       cyclingitems.com
       elong-led.com
       emailber.com
       fulldesigns.net
       grow-mail.com
       inemaling.com
       inmailing.com
       itemailing.com
       itmailing.com
       juchanghn.com
       kod-emailing.com
       kod-maling.com
       kodemailing.com
       kodmailing.com
       left-mail.com
       mabermail.com
       mailphar.com
       msqmakeupbrush.com
       out-email.com
       semi-mile.com
       showerspasystem.com
       sin-mailing.com
       sinemailing.com
       sinmailing.com
       takmailing.com
       themailemail.com
       visitinbox.com
       webgarden.com
       webgarden.cz
       wgz.cz
       wowmailing.com).freeze
  DEFAULT_SPAM_NAME_FORMATS = [
    /\A.*bitcoin.*\z/i,
    /\A.*currency.*\z/i,
    /\A.*support.*\z/i,
    /\A.*customer.*service.*\z/i,
    /\A.*customer.*care.*\z/i,
    /\A.*buy.*online.*\z/i,
    /\A.*real.*estate.*\z/i,
    /\A.*web.*design.*\z/i,
    /\A.*Mac\sDesktop.*\z/i,
    /\A.*Inc\z/,
    /\A.*LLC\z/,
    /\A.*spyware.*\z/i,
    /\A.*malware.*\z/i,
    /\A.*CRM.*\z/
  ].freeze
  DEFAULT_SPAM_ABOUT_ME_FORMATS = [
    /\A.+\n{2,}https?:\/\/[^\s]+\z/,
    /\Ahttps?:\/\/[^\s]+\n{2,}.+$/,
    /\A.*\n{2,}.*\n{2,}https?:\/\/[^\s]+$/
  ].freeze
  DEFAULT_SPAM_SCORE_THRESHOLD = 4
  DEFAULT_SPAM_TLDS = %w(ru pl).freeze
  DEFAULT_SUSPICIOUS_USER_AGENTS = [].freeze
  DEFAULT_SUSPICIOUS_IP_RANGES = [].freeze

  CLASS_ATTRIBUTES = [:currency_symbols,
                      :score_mappings,
                      :suspicious_domains,
                      :spam_domains,
                      :spam_name_formats,
                      :spam_about_me_formats,
                      :spam_score_threshold,
                      :spam_tlds,
                      :suspicious_user_agents,
                      :suspicious_ip_ranges].freeze

  # Class attribute accessors
  CLASS_ATTRIBUTES.each do |key|
    define_singleton_method "#{ key }=" do |value|
      instance_variable_set("@#{ key }", value)
    end

    define_singleton_method key do
      value = instance_variable_get("@#{ key }") ||
              const_get("DEFAULT_#{ key }".upcase)
      instance_variable_set("@#{ key }", value)
    end
  end

  def self.reset
    CLASS_ATTRIBUTES.each do |key|
      instance_variable_set("@#{ key }", const_get("DEFAULT_#{ key }".upcase))
    end
  end

  # Instance attribute accessors
  CLASS_ATTRIBUTES.each do |key|
    attr_reader key
  end

  def initialize(opts = {})
    CLASS_ATTRIBUTES.each do |key|
      instance_variable_set("@#{ key }", opts.fetch(key, self.class.send(key)))
    end
  end

  def spam?(user)
    score(user) > spam_score_threshold
  end

  def score(user)
    return 0 if user.comments.any? || user.track_things.any?
    score_mappings.inject(0) do |score_count, score_mapping|
      if send(score_mapping.first, user)
        score_count + score_mapping.last
      else
        score_count
      end
    end
  end

  def name_is_all_lowercase?(user)
    user.name == user.name.downcase
  end

  def name_is_one_word?(user)
    !(user.name =~ /\s/)
  end

  def name_includes_non_alpha_characters?(user)
    !(user.name.strip =~ /\A[a-zA-Z\s]+\z/i)
  end

  def name_is_garbled?(user)
    user.name.strip =~ /[^aeiou]{5,}/i ? true : false
  end

  def email_from_suspicious_domain?(user)
    suspicious_domains.include?(user.email_domain)
  end

  def email_from_spam_domain?(user)
    spam_domains.include?(user.email_domain)
  end

  def email_from_spam_tld?(user)
    spam_tlds.any? { |tld| user.email_domain.split('.').last == tld }
  end

  def name_is_spam_format?(user)
    spam_name_formats.any? { |regexp| user.name.strip =~ regexp }
  end

  def about_me_includes_currency_symbol?(user)
    currency_symbols.any? { |symbol| user.about_me.include?(symbol) }
  end

  def about_me_is_link_only?(user)
    user.about_me.strip =~ /\Ahttps?:\/\/[^\s]+\z/i ? true : false
  end

  def about_me_is_spam_format?(user)
    spam_about_me_formats.any? do |regexp|
      user.about_me.gsub("\r\n", "\n").strip =~ regexp
    end
  end

  def about_me_includes_anchor_tag?(user)
    user.about_me =~ /<a.*href=('|")/ ? true : false
  end

  def about_me_already_exists?(user)
    user.about_me_already_exists?
  end

  def user_agent_is_suspicious?(user)
    return false unless user.respond_to?(:user_agent)
    suspicious_user_agents.include?(user.user_agent)
  end

  def ip_range_is_suspicious?(user)
    return false unless user.respond_to?(:ip)
    suspicious_ip_ranges.any? { |range| range.include?(user.ip) }
  end

  # TODO: Akismet thinks user is spam
  # TODO: About me includes spam words/phrases
  # TODO: About me includes URLs that do not resolve
  # TODO: User has no transactions
  # TODO: About me includes non-english characters
end

# -*- encoding : utf-8 -*-
class UserSpamScorer
  DEFAULT_SCORE_MAPPINGS = {
    :name_is_all_lowercase? => 1,
    :name_is_one_word? => 1,
    :name_includes_non_alpha_characters? => 3,
    :name_is_garbled? => 5,
    :email_from_spam_domain? => 5,
    :email_from_spam_tld? => 3,
    :about_me_includes_currency_symbol? => 2,
    :about_me_is_link_only? => 3,
    :about_me_is_spam_format? => 1,
    :about_me_includes_anchor_tag? => 1,
    :about_me_already_exists? => 4
  }.freeze

  DEFAULT_CURRENCY_SYMBOLS = %w(£ $ € ¥ ¢).freeze
  DEFAULT_SPAM_DOMAINS = %w(mail.ru temp-mail.de tempmail.de shitmail.de).freeze
  DEFAULT_SPAM_FORMATS = [
    /\A.+\n{2,}https?:\/\/[^\s]+\z/,
    /\Ahttps?:\/\/[^\s]+\n{2,}.+$/,
    /\A.*\n{2,}.*\n{2,}https?:\/\/[^\s]+$/
  ].freeze
  DEFAULT_SPAM_SCORE_THRESHOLD = 4
  DEFAULT_SPAM_TLDS = %w(ru pl).freeze

  CLASS_ATTRIBUTES = [:currency_symbols,
                      :score_mappings,
                      :spam_domains,
                      :spam_formats,
                      :spam_score_threshold,
                      :spam_tlds].freeze

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

  def email_from_spam_domain?(user)
    spam_domains.include?(user.email_domain)
  end

  def email_from_spam_tld?(user)
    spam_tlds.any? { |tld| user.email_domain.split('.').last == tld }
  end

  def about_me_includes_currency_symbol?(user)
    currency_symbols.any? { |symbol| user.about_me.include?(symbol) }
  end

  def about_me_is_link_only?(user)
    user.about_me.strip =~ /\Ahttps?:\/\/[^\s]+\z/i ? true : false
  end

  def about_me_is_spam_format?(user)
    spam_formats.any? do |regexp|
      user.about_me.gsub("\r\n", "\n").strip =~ regexp
    end
  end

  def about_me_includes_anchor_tag?(user)
    user.about_me =~ /<a.*href=('|")/ ? true : false
  end

  def about_me_already_exists?(user)
    user.about_me_already_exists?
  end

  # TODO: Akismet thinks user is spam
  # TODO: About me includes spam words/phrases
  # TODO: About me includes URLs that do not resolve
  # TODO: User has no transactions
  # TODO: About me includes non-english characters
end

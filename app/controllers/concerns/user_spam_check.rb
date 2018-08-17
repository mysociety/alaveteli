module UserSpamCheck
  extend ActiveSupport::Concern

  private

  def spam_should_be_blocked?
    raise NotImplementedError
  end

  def spam_user?(user)
    user_with_request = User::WithRequest.new(user, request)
    UserSpamScorer.new(spam_scorer_config).spam?(user_with_request)
  end

  def handle_spam_user(user, &block)
    msg = "Attempted signup from suspected spammer, " \
          "email: #{user.email}, " \
          "name: '#{user.name}'"

    if spam_should_be_blocked?
      logger.info(msg)
      block.call if block_given?

      true
    elsif send_exception_notifications?
      e = Exception.new(msg)
      ExceptionNotifier.notify_exception(e, :env => request.env)

      false
    end
  end

  def spam_scorer_config
    {
      spam_score_threshold: 13,
      score_mappings: {
        name_is_all_lowercase?: 1,
        name_is_one_word?: 1,
        name_includes_non_alpha_characters?: 1,
        name_is_garbled?: 1,
        email_from_suspicious_domain?: 10,
        email_from_spam_domain?: 13,
        email_from_spam_tld?: 1,
        name_is_spam_format?: 10,
        about_me_includes_currency_symbol?: 0,
        about_me_is_link_only?: 0,
        about_me_is_spam_format?: 0,
        about_me_includes_anchor_tag?: 0,
        about_me_already_exists?: 0,
        user_agent_is_suspicious?: 3,
        ip_range_is_suspicious?: 10
      }
    }
  end
end

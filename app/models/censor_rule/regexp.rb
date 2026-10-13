# CensorRules can use a Regexp pattern to match content
module CensorRule::Regexp
  extend ActiveSupport::Concern

  included do
    validate :require_valid_regexp,
             if: -> { regexp? || !case_sensitive? || ignore_diacritics? }
  end

  private

  def require_valid_regexp
    make_regexp('UTF-8')
  rescue RegexpError => e
    errors.add(:text, e.message)
  end

  def make_regexp(encoding)
    pattern =
      if ignore_diacritics?
        diacritic_expander.expand(encoded_text(encoding))
      else
        encoded_text(encoding)
      end

    pattern = Regexp.escape(pattern) unless regexp? || ignore_diacritics?

    ::Warning.with_raised_warnings do
      Regexp.new(pattern, regexp_options)
    end
  rescue RaisedWarning => e
    raise RegexpError, e.message.split('warning: ').last.chomp
  end

  def regexp_options
    options = 0
    options |= Regexp::IGNORECASE unless case_sensitive?
    options |= Regexp::MULTILINE if regexp?
    options
  end
end

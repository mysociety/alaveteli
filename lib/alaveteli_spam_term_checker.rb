# -*- encoding : utf-8 -*-
class AlaveteliSpamTermChecker
  DEFAULT_SPAM_TERMS = [
    /Freedom of Information request - [\{\[\|]/i,
    /Sea?,?s?o?n?[ -.]\d+[ -]Epi?'?s?,?o?d?e?s?[ -.]\d+/i,
    /\[Full-Watch\]/i,
    /free-watch/i,
    /Online Full 2016/i,
    /HD | Special ".*?" Online/i,
    /FULL .O?N?_?L?I?N?E? ?\.?MOVIE/i,
    /\[Full 20x5\]/i,
    /Putlocker/i,
    /se?\d+ep?\d+/i,
    /\[free\]/i,
    /vodlocker/i,
    /online free full/i,
    /streaming 2016/i,
    /films?-?hd/i,
    /\[DVDscr\]/i,
    /W@tch/i,
    /720p/i,
    /1080p/i,
    /MEGA.TV/i,
    /1080.HD/i,
    /\[Online-Free\]/i,
    /\[HD\]/i,
    /\{DOWNLOAD\}/i,
    /\(\{Ganzer FIlm\}\)/i,
    /\{leak\}/i,
    /MEGASH[a|e]RE?/i,
    /\[Official.HD\]/i,
    /Completa.*?Ver Online Gratis/i,
    /Assistir.*?Completa Film Portuguese/i,
    /\[MP3\]/i,
    /Watch.*?Movie Online/i,
    /Gratuitement.*?TELECHARGER/i,
    /full album/i,
    /album complet/i,
    /Album.*?Gratuit/i,
    /Free.Download/i,
    /\{FR\}/i,
    /\[Album\]/i,
    /watch.*?online free/i,
    /bangalore.*?escort/i,
    /escort.*?bangalore/i,
    /depfile/i,
    /brazzers/i,
    /brazzer/i,
    /gardenscapes\snew\sacres/i,
    /les\ssimpson\sspringfield\shack/i,
    /bitbon/i
  ].freeze

  def self.default_spam_terms
    @default_spam_terms ||= build_terms(DEFAULT_SPAM_TERMS)
  end

  def self.default_spam_terms=(terms)
    @default_spam_terms = build_terms(terms)
  end

  # Private: Convert term/s in to an Array of Regexps
  #
  # terms - Single object or Array of objects that can be passed to Regexp#new
  #
  # Returns an Array
  def self.build_terms(terms)
    Array(terms).map { |term| Regexp.new(term) }
  end

  attr_reader :spam_terms

  def initialize(terms = nil)
    @spam_terms = if terms
      build_terms(terms)
    else
      self.class.default_spam_terms
    end
  end

  def spam?(term)
    spam_terms.any? { |spam_term| term =~ spam_term }
  end

  private

  def build_terms(terms)
    self.class.build_terms(terms)
  end
end

# Maps characters to a regexp covering its diacritic variants.
class CensorRule::Diacritics::DiacriticExpander
  # Maps each character to cover diacritic variants. Separate lowercase and
  # uppercase entries preserve the original case of the input — when
  # case_sensitive is false Regexp::IGNORECASE covers the other case without
  # enumerating both in each class.
  #
  # Reusers can replace or extend this for their locale:
  #   CensorRule::DiacriticExpander.character_map = { ... }
  DEFAULT_CHARACTER_MAP = {
    'a' => '[aàáâãäåā]', 'A' => '[AÀÁÂÃÄÅĀ]',
    'c' => '[cçćč]',     'C' => '[CÇĆČ]',
    'e' => '[eèéêëēě]',  'E' => '[EÈÉÊËĒĚ]',
    'i' => '[iìíîïī]',   'I' => '[IÌÍÎÏĪ]',
    'l' => '[lłĺļľ]',    'L' => '[LŁĹĻĽ]',
    'n' => '[nñńň]',     'N' => '[NÑŃŇ]',
    'o' => '[oòóôõöøō]', 'O' => '[OÒÓÔÕÖØŌ]',
    'r' => '[rŕř]',      'R' => '[RŔŘ]',
    's' => '[sśš]',      'S' => '[SŚŠ]',
    'u' => '[uùúûüūů]',  'U' => '[UÙÚÛÜŪŮ]',
    'y' => '[yýÿ]',      'Y' => '[YÝŸ]',
    'z' => '[zźżž]',     'Z' => '[ZŹŻŽ]',
    'œ' => '(œ|oe)',     'Œ' => '(Œ|OE)',
    'æ' => '(æ|ae)',     'Æ' => '(Æ|AE)'
  }.freeze

  cattr_accessor :character_map, default: DEFAULT_CHARACTER_MAP

  def initialize(case_sensitive: true)
    @case_sensitive = case_sensitive
  end

  def expand(text, encoding: 'UTF-8')
    text.mb_chars.each_char.map { expand_character(it) }.join.encode(encoding)
  end

  def case_sensitive?
    @case_sensitive
  end

  private

  def expand_character(char)
    map = character_map_case_insensitive || character_map

    map[char] ||
      map[ActiveSupport::Inflector.transliterate(char)] ||
      char
  end

  def character_map_case_insensitive
    return if case_sensitive?

    lowercase_keys = character_map.each_key.select { |k| k == k.downcase }

    lowercase_keys.each_with_object({}) do |lower, combined_map|
      upper = lower.upcase

      lower_chars = character_map.fetch(lower)[1...-1]
      upper_chars = character_map.fetch(upper)[1...-1]

      combined = "[#{lower_chars}#{upper_chars}]"

      combined_map[lower] = combined
      combined_map[upper] = combined
    end
  end
end

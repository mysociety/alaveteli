class Legislation
  module Constants
    TYPE = /([a-z]+)/i
    ELEMENT = /([a-z0-9]+)/i
    NUM_ELEMENT = /([0-9]+)/i
    BRACKETED_ELEMENT = /\(#{ELEMENT}\)/
    DECIMAL_ELEMENT = /\.#{ELEMENT}/
    SUB_ELEMENTS = /#{BRACKETED_ELEMENT}|#{DECIMAL_ELEMENT}/
    ALL_ELEMENTS = /#{ELEMENT}|#{SUB_ELEMENTS}/

    SPACE_OR_DOT = /\s*|\.\s*/
    AND_SEPARATOR = /&(?:amp;)?/
    OR_SEPARATOR = /,\s*|\s*or\s*/i

    # Match whole references strings
    REGEXP = /
      #{TYPE}
      #{SPACE_OR_DOT}?
      (
        (?:
          #{NUM_ELEMENT}
          (?:
            \s*
            (?:#{SUB_ELEMENTS})+
            (?:#{AND_SEPARATOR}#{ALL_ELEMENTS})*
          )?
          #{OR_SEPARATOR}?
        )+
      )
    /x

    # Match references with AND separator, with named capture groups for easier
    # replacement
    AND_REGEXP = /
      \b
      (?<sup>.*?)
      \.
      (?<sub_1>#{ELEMENT})
      #{AND_SEPARATOR}
      \.?
      (?<sub_2>#{ELEMENT})
      \b
    /x
  end
end

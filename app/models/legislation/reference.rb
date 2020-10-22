class Legislation
  InvalidReferenceType = Class.new(StandardError)

  ##
  # Reference representing a section of a legislation
  #
  # See https://en.wikipedia.org/wiki/Citation_of_United_Kingdom_legislation#Primary_legislation
  #
  # Example:
  #   Legislation::Reference.new(legislation: foi, reference: 's 12(1)') =>
  #     #<Legislation::Reference
  #       @legislation=foi,
  #       @type="Section",
  #       @elements=["12", "1"]>
  #
  class Reference
    attr_reader :legislation, :type, :elements

    def initialize(legislation:, reference:)
      @legislation = legislation

      type, elements = *reference.split(' ', 2)
      @type = parse_type(type)
      @elements = elements.gsub(
        /\.?#{Constants::BRACKETED_ELEMENT}/,
        '.\1'
      ).split('.')
    end

    def to_s
      base = "#{type} #{main_element}"
      return base if sub_elements.empty?
      base + "(#{sub_elements.join(')(')})"
    end

    private

    def main_element
      elements[0]
    end

    def sub_elements
      elements[1..-1]
    end

    def parse_type(type)
      case type.downcase
      when 's', 'section'
        _('Section')
      when 'art', 'article'
        _('Article')
      when 'reg', 'regulation'
        _('Regulation')
      else
        raise InvalidReferenceType,
          "Unknown legislation reference type #{type}."
      end
    end
  end
end

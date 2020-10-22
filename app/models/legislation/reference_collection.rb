class Legislation
  ##
  # Collection of legislation references belonging to a legislation.
  #
  # This is a wrapper for the legislation references detection routine.
  # See Legislation::ReferenceCollection#match
  #
  class ReferenceCollection
    include Constants

    attr_reader :legislation

    def initialize(legislation:)
      @legislation = legislation
    end

    ##
    # Detect legislation references in a string value.
    #
    # Example:
    #   collection = Legislation::ReferenceCollection.new(legislation: foia)
    #   collection.match('Section 12(1)', legislation: foia) => [
    #     #<Legislation::Reference
    #       @legislation=foia,
    #       @type="Section",
    #       @elements=["12", "1"]>
    #   ]
    def match(text)
      text.scan(REGEXP).inject([]) do |references, capture|
        type = capture[0]

        parse_matches(capture[1]).each do |reference|
          begin
            references << Legislation::Reference.new(
              legislation: legislation, reference: "#{type} #{reference}"
            )
          rescue Legislation::InvalidReferenceType
            # noop
          end
        end

        references
      end
    end

    private

    def parse_matches(string)
      string.
        # convert &amps; into &
        gsub(/#{AND_SEPARATOR}/, '&').
        # remove spaces before sub elements
        gsub(/\s+(#{SUB_ELEMENTS})/, '\1').
        # convert bracketed elements into decimal elements for easier processing
        gsub(/\.?#{BRACKETED_ELEMENT}/, '.\1').
        # split at AND separators into two distinct references
        gsub(AND_REGEXP, '\k<sup>.\k<sub_1> or \k<sup>.\k<sub_2>').
        # convert decimal elements back into preferred bracketed elements
        gsub(/#{DECIMAL_ELEMENT}/, '(\1)').
        # split OR separators into an array
        split(/#{OR_SEPARATOR}/).
        # just in case, remove any blank references
        reject(&:blank?)
    end
  end
end

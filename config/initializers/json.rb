 module ActiveSupport
  module JSON
    module Encoding
      private
      class EscapedString
        def to_s
          self
        end
      end
    end
  end
end

# Common values for CensorRule#replacement
module CensorRule::CannedReplacements
  extend ActiveSupport::Concern

  included do
    DEFAULT_CANNED_REPLACEMENTS = [
      _('[Personally Identifiable Information removed]'),
      _('[name removed]'),
      _('[extraneous material removed]'),
      _('[potentially defamatory material removed]'),
      _('[extraneous and potentially defamatory material removed]')
    ].freeze

    cattr_accessor :canned_replacements,
                   instance_writer: false,
                   default: DEFAULT_CANNED_REPLACEMENTS.dup
  end
end

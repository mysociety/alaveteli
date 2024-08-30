##
# This module that provides functionality for managing source content and
# output attachments in a workflow process.
#
module Workflow::Source
  extend ActiveSupport::Concern

  included do
    has_one_attached :output, service: :workflows

    validates :output, presence: true, if: -> { _1.completed? }
  end

  def source
    # TODO: remove #chunk_text, needs knowledge of chunkable concern

    @source ||= parent.output&.open(&:read) if parent&.completed?
    (@source || resource.chunk_text). encode(
      'UTF-8',
      'ASCII-8BIT',
      invalid: :replace,
      undef: :replace,
      replace: ' '
    ).compact.strip
  end

  def source=(string)
    @source = string

    output.attach(
      io: StringIO.new(string.to_s),
      filename: filename,
      content_type: content_type
    )
  end

  private

  def filename
    [resource.class, resource.id, self.class.name].join('-')
  end
end

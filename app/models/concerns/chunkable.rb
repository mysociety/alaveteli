##
# Chunkable Concern
#
# This concern provides functionality for processing instance through a
# chunking workflow and delegating to other assoicated objects.
#
# Usage:
#   class YourModel < ApplicationRecord
#     include Chunkable
#     chunkable column: :content, delegate_to: -> { associated_records }
#   end
#
# Configuration options:
#   - column: (Symbol) The name of the column containing the text to be chunked.
#   - delegate_to: (Proc) A lambda or proc that returns an array of associated
#     records to chunk.
#
module Chunkable
  extend ActiveSupport::Concern

  def self.config
    @config ||= {}
  end

  included do
    def self.chunkable(**args)
      Chunkable.config[self] = args
    end

    has_many :chunks, ->(resource) { where(resource.chunk_assoications) },
                      dependent: :destroy
  end

  def chunk!
    chunk_workflow.run if chunk_text
    chunk_delegate!
    nil
  end

  def chunk_text
    return unless chunkable_config[:column]

    public_send(chunkable_config[:column])
  end

  def chunk_delegate!
    return unless chunkable_config[:delegate_to]

    public_send(chunkable_config[:delegate_to]).each(&:chunk!)
  end

  def chunk_assoications
    assoication = Chunkable.config.inject(nil) do |name, (klass, c)|
      next name unless c[:delegate_to]

      delegate_reflection = klass.reflect_on_association(c[:delegate_to])
      next name unless delegate_reflection&.klass == self.class

      delegate_reflection.inverse_of.name || name
    end

    parent = public_send(assoication) if assoication
    return {} unless parent

    { assoication => parent }.merge(parent.chunk_assoications)
  end

  private

  def chunk_workflow
    Workflow.example(self)
  end

  def chunkable_config
    Chunkable.config[self.class]
  end
end

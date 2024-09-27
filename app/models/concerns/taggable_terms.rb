require 'set'

# Apply tags to a Taggable record based on configured attributes matching terms
# mapped to tags get applied when there is a match.
#
# Example:
#
#   Record.taggable_terms = { body: { /foo/ => 'foo' } }
#   r = Record.new
#   r.tagged?('foo')
#   # => false
#
#   r.update(body: 'foo bar baz')
#   r.tagged?('foo')
#   # => true
module TaggableTerms
  extend ActiveSupport::Concern

  included do
    cattr_accessor :taggable_terms, default: {}
    before_save :update_taggable_terms, if: :taggable_term_attribute_changed?
  end

  def update_taggable_terms
    tags_to_add, tags_to_remove = taggable_terms_changed_tags
    tags_to_add.each { |tag| add_tag_if_not_already_present(tag) }
    tags_to_remove.each { |tag| remove_tag(tag) }
  end

  private

  def taggable_term_attribute_changed?
    changed.include?(taggable_terms.keys)
  end

  def taggable_terms_changed_tags
    tags_to_add = Set.new
    tags_to_remove = Set.new

    taggable_terms_to_tag_to_attr_terms.each do |tag, attr_terms_pairs|
      tag_str = tag.to_s

      attr_terms_pairs.each do |attr, term|
        if attribute_matches_taggable_term?(attr, term)
          tags_to_add << tag_str
          break
        end
      end

      tags_to_remove << tag_str unless tags_to_add.include?(tag_str)
    end

    [tags_to_add, tags_to_remove]
  end

  def attribute_matches_taggable_term?(attr, term)
    read_attribute(attr) =~ Regexp.new(term)
  end

  # Restructure taggable_terms so that it's more processing friendly
  #
  # Before:
  # => {:body=>{/train/i=>"trains", /bus/i=>"bus", /locomotive/i=>"trains"}}
  #
  # After:
  # => {"trains"=>[[:body, /train/i], [:body, /locomotive/i]],
  #     "bus"=>[[:body, /bus/i]]}
  def taggable_terms_to_tag_to_attr_terms
    seed = Hash.new { |h, k| h[k] = [] }

    taggable_terms.each_with_object(seed) do |(attr, terms_tags), memo|
      terms_tags.each do |term, tag|
        memo[tag] << [attr, term]
      end
    end
  end
end

module TaggableTerms
  extend ActiveSupport::Concern

  included do
    cattr_accessor :taggable_terms, default: {}
    before_save :update_taggable_terms, if: :taggable_term_attribute_changed?
  end

  def update_taggable_terms
    taggable_terms.each do |attr, terms_tags|
      terms_tags.each do |term, tag|
        if attribute_matches_taggable_term?(attr, term)
          add_tag_if_not_already_present(tag.to_s)
        else
          unless tag_applied_via_other_taggable_term?(tag, attr)
            remove_tag(tag.to_s)
          end
        end
      end
    end
  end

  private

  def taggable_term_attribute_changed?
    changed.include?(taggable_terms.keys)
  end

  def attribute_matches_taggable_term?(attr, term)
    read_attribute(attr) =~ Regexp.new(term)
  end

  def tag_applied_via_other_taggable_term?(tag, attr)
    taggable_terms[attr].
      select { |_, other_tag| other_tag == tag }.
      any? { |term, _| attribute_matches_taggable_term?(attr, term) }
  end
end

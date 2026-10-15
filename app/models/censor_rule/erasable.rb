# Erasing a CensorRule removes the content it matches – which may itself be
# personal information – while keeping the record as an audit trail of the
# rule having existed.
#
# Erased rules no longer apply, so any redactions they made must be made
# permanent before erasure (see CensorRule::Permanence).
module CensorRule::Erasable
  extend ActiveSupport::Concern

  included do
    scope :erased, -> { where.not(erased_at: nil) }
    scope :not_erased, -> { where(erased_at: nil) }

    # Rules that only affect a single user's content. Making a global or
    # PublicBody rule permanent would lock content across many users' requests.
    scope :erasable, -> {
      not_erased.where(censorable_type: %w[User InfoRequest])
    }
  end

  def erased?
    erased_at.present?
  end

  def erasable?
    !erased? && %w[User InfoRequest].include?(censorable_type)
  end

  def erase(editor:)
    return true if erased?

    update!(
      text: '',
      replacement: '',
      erased_at: Time.zone.now,
      last_edit_editor: editor
    )
  end
end

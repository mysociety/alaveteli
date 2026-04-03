module User::Erasable
  extend ActiveSupport::Concern

  def erase_later(editor:, reason:)
    User::ErasureJob.perform_later(self, editor: editor, reason: reason)
  end

  def erase(...)
    erase!(...)
  rescue ActiveRecord::RecordInvalid
    false
  end

  def erase!(editor:, reason:)
    raise ActiveRecord::RecordInvalid unless closed?
    raise RawEmail::UnmaskedAttachmentsError unless all_attachments_masked?

    transaction do
      destroy_identifying_associations
      make_request_redactions_permanent(editor: editor, reason: reason)
      erase_account
    end
  end

  private

  def destroy_identifying_associations
    slugs.destroy_all
    sign_ins.destroy_all
    email_histories.destroy_all
    profile_photo&.destroy!
  end

  def make_request_redactions_permanent(...)
    outgoing_messages.update!(from_name: _('[Name Removed]'))
    info_requests.find_each { |request| request.make_redactions_permanent(...) }
  end

  def erase_account
    sha = Digest::SHA1.hexdigest(rand.to_s)

    update!(
      name: _('[Name Removed]'),
      email: "#{sha}@invalid",
      url_name: sha,
      about_me: '',
      password: MySociety::Util.generate_token
    )
  end
end

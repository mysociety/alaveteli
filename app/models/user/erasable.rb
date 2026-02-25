module User::Erasable
  extend ActiveSupport::Concern

  def erase
    erase!
  rescue ActiveRecord::RecordInvalid
    false
  end

  def erase!
    raise ActiveRecord::RecordInvalid unless closed?

    transaction do
      destroy_identifying_associations

      outgoing_messages.update!(
        from_name: _('[Name Removed]')
      )

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

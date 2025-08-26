class PublicBodyChangeRequestMailerPreview < ActionMailer::Preview
  def add_public_body
    PublicBodyChangeRequestMailer.add_public_body(new_request)
  end

  def update_public_body
    PublicBodyChangeRequestMailer.update_public_body(update_request)
  end

  private

  def new_request
    PublicBodyChangeRequest.new(
      id: 1,
      user: User.first,
      source_url: 'http://source.example.com',
      notes: 'Please add',
      public_body_email: 'new@localhost',
      public_body_name: 'New public body'
    )
  end

  def update_request
    PublicBodyChangeRequest.new(
      id: 1,
      user: User.first,
      source_url: 'http://source.example.com',
      notes: 'Please update',
      public_body_email: 'new@localhost',
      public_body: PublicBody.first
    )
  end
end

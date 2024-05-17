class ContactMailerPreview < ActionMailer::Preview
  def user_message
    ContactMailer.user_message(
      bob, alice, 'http://www.example.org/user/bob/profile',
      'Mail from an user', 'Great request'
    )
  end

  def from_admin_message
    ContactMailer.from_admin_message(
      bob.name, bob.email, 'Mail from an admin', 'Bad request'
    )
  end

  private

  def bob
    User.new(id: 1, name: 'Bob', email: 'bob@localhost')
  end

  def alice
    User.new(id: 2, name: 'Alice', email: 'alice@localhost')
  end
end

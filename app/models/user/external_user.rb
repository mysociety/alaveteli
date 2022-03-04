# Specialisations for handling requests made externally and mirrored to
# Alaveteli.
class User::ExternalUser < User
  def initialize(info_request:)
    @info_request = info_request
  end

  def name
    info_request.external_user_name || _('Anonymous user')
  end

  def url_name
    fake_slug = MySociety::Format.simplify_url_part(name, 'external_user', 32)
    (info_request&.public_body&.url_name || '') + '_' + fake_slug
  end

  def prominence
    'backpage'
  end

  def censor_rules
    []
  end

  def flipper_id
    'User;external'
  end

  def is_pro?
    false
  end

  def json_for_api
    { name: name }
  end

  def external?
    true
  end

  protected

  attr_reader :info_request
end

# Helpers for Datasette integration
module DatasetteHelper
  include InfoRequestHelper

  mattr_accessor :datasette_url, default: 'https://lite.datasette.io/'

  def explore_in_datasette(attachment)
    return unless explorable_in_datasette?(attachment)

    datasette_attachment_url =
      add_query_params_to_url(datasette_url, csv: attachment_url(attachment))

    link_to _('Explore in Datasette'), datasette_attachment_url
  end

  private

  def explorable_in_datasette?(attachment)
    return false unless attachment.is_public?
    return false unless attachment.incoming_message.is_public?
    return false unless info_request_is_public?(attachment)
    return false unless attachment.content_type == 'text/csv'

    true
  end

  def info_request_is_public?(attachment)
    attachment.
      incoming_message.
      info_request.
      prominence(decorate: true).
      is_public?
  end
end

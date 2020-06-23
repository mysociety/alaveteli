##
# Helper methods relating to file downloads
#
module DownloadHelper
  def generate_download_filename(resource:, id:, title:, type: nil, ext:)
    url_title = MySociety::Format.simplify_url_part(
      title, resource, 32
    )
    url_title += "-#{type}" if type
    timestamp = Time.zone.now.to_formatted_s(:filename)

    "#{resource}-#{id}-#{url_title}-#{timestamp}.#{ext}"
  end
end

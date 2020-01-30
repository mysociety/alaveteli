##
# Helper methods relating to file downloads
#
module DownloadHelper
  def generate_download_filename(resource:, id:, title:, type:, ext:)
    url_title = MySociety::Format.simplify_url_part(
      title, resource, 32
    )
    timestamp = Time.zone.now.to_formatted_s(:filename)

    "#{resource}-#{id}-#{url_title}-#{type}-#{timestamp}.#{ext}"
  end
end

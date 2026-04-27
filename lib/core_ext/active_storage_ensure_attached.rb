##
# Prevent serving blobs that are not attached to any record.
# By default ActiveStorage serves any blob with a valid signed ID,
# even if it has been detached or never attached.
#
module ActiveStorage::EnsureAttached
  private

  def set_blob
    super
    head :not_found unless @blob.attachments.exists?
  end
end

Rails.application.config.after_initialize do
  ActiveStorage::SetBlob.prepend(ActiveStorage::EnsureAttached)
end

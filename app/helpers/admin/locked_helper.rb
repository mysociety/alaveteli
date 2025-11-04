##
# Helpers for handling locked status of incoming messages or attachments in the
# admin interface
#
module Admin::LockedHelper
  def locked_icon(resource)
    return unless resource.locked?

    tag.i class: 'icon-foi-attachment--locked', title: 'locked'
  end
end

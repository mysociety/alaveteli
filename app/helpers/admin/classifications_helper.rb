# Helpers for displaying classifications in the admin interface
module Admin::ClassificationsHelper
  def classification_icon(info_request)
    classification = info_request.calculate_status
    css_class = "classification_icon classification_icon--#{ classification }"
    tag.i class: css_class, title: info_request.display_status(true)
  end
end

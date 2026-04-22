##
# Extends has_rich_text with a strip_attachments option that removes
# <action-text-attachment> nodes before save, preventing file uploads
# from being persisted in rich text fields.
#
module ActionTextExtensions
  extend ActiveSupport::Concern

  class_methods do
    def has_rich_text(name, strip_attachments: false, **options)
      super(name, **options)
      return unless strip_attachments

      callback = :"strip_#{name}_attachments"

      before_save callback

      define_method(callback) do
        rich_text = send(:"rich_text_#{name}")
        return unless rich_text&.body&.present?

        doc = Nokogiri::HTML.fragment(rich_text.body.to_html)
        doc.css('action-text-attachment').each(&:remove)
        rich_text.body = ActionText::Content.new(doc.to_html)
      end

      private callback
    end
  end
end

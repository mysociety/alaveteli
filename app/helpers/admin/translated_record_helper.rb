# Helpers for managing records with translations
module Admin::TranslatedRecordHelper
  def translated_form_for(name, *args, &block)
    options = args.extract_options!
    args << options.merge(builder: Admin::TranslatedRecordForm)
    form_for(name, *args, &block)
  end
end

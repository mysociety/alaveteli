module AdminPublicBodyHelper

    def public_body_form_object(public_body, locale)
        if locale == I18n.default_locale
            # The default locale is submitted as part of the bigger object...
            prefix = 'public_body'
            object = public_body
        else
            # ...but additional locales go "on the side"
            prefix = 'public_body[translated_versions][]'
            object = if public_body.new_record?
                         PublicBody::Translation.new
                     else
                        public_body.find_translation_by_locale(locale.to_s)
                     end
            object ||= PublicBody::Translation.new
        end

        { :object => object, :prefix => prefix }
    end

end

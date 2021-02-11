# FormBuilder for records translated with Globalize
class Admin::TranslatedRecordForm < ActionView::Helpers::FormBuilder
  def translated_fields
    fields = @template.tag.div id: 'div-locales' do
      @template.concat(locale_tabs)

      locales = @template.tag.div class: 'tab-content' do
        object.ordered_translations.each do |translation|
          locale = translation.locale

          content = tab_pane(locale) do
            if AlaveteliLocalization.default_locale?(locale)
              @template.fields_for(object) do |t|
                locale_fields(t, locale) do
                  yield t
                end
              end
            else
              fields_for(:translations, translation, child_index: locale) do |t|
                locale_fields(t, locale) do
                  yield t
                end
              end
            end
          end

          @template.concat(content)
        end
      end

      @template.concat(locales)
    end

    @template.concat(fields)
  end

  private

  def locale_tabs
    @template.tag.ul class: 'locales nav nav-tabs' do
      object.ordered_translations.each do |translation|
        li = @template.tag.li do
          href = "#div-locale-#{translation.locale}"

          link = @template.link_to href, data: { toggle: 'tab' } do
            @template.concat(locale_name(translation.locale))
          end

          @template.concat(link)
        end

        @template.concat(li)
      end
    end
  end

  def tab_pane(locale)
    @template.tag.div id: "div-locale-#{locale}", class: 'tab-pane' do
      yield
    end
  end

  def locale_fields(t, locale)
    @template.concat t.hidden_field :locale, value: locale
    yield
  end

  # TODO: Also defined in ApplicationHelper; extract to LocaleHelper and include
  # here.
  def locale_name(locale)
    LanguageNames.get_language_name(locale.to_s) || locale.to_s
  end

  # TODO: make available everywhere
  def default_locale
    AlaveteliLocalization.default_locale
  end
end

# -*- encoding : utf-8 -*-
# Helpers for classifications
module ClassificationsHelper
  def classification_radio_button(state, id_suffix: nil)
    id = "#{ state }#{ id_suffix }"
    radio_button 'classification', 'described_state', state, id: id
  end

  def classification_label(state, text, id_suffix: nil)
    id = "#{ state }#{ id_suffix }"
    label_tag(id, text)
  end
end

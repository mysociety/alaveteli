# -*- encoding : utf-8 -*-
# Helpers for classifications
module ClassificationsHelper
  def classification_radio_button(state, id_suffix: nil)
    id = "#{ state }#{ id_suffix }"
    radio_button 'classification', 'described_state', state, id: id
  end
end

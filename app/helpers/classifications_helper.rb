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

  def user_classification_milestone?(number)
    return false unless number.is_a?(Integer) && number > 0

    num_str = number.to_s

    # round numbers (100, 1000, 10000, etc.)
    return true if num_str.match?(/^100+$/)

    # 250x pattern numbers (250, 2500, 25000, etc.)
    return true if num_str.match?(/^250+$/)

    # 500x pattern numbers (500, 5000, 50000, etc.)
    return true if num_str.match?(/^500+$/)

    # 750x pattern numbers (750, 7500, 75000, etc.)
    return true if num_str.match?(/^750+$/)

    # repeated digits (6666, 7777, etc.)
    return true if num_str.chars.uniq.length == 1 && num_str.length > 4

    # palindromic numbers (42424, 12321, etc.)
    return true if num_str == num_str.reverse && num_str.length > 4

    # sequential or descending digits (12345, 56789, 54321, 98765, etc.)
    digits = num_str.chars.map(&:to_i)
    if digits.length > 4
      is_ascending_sequential = true
      is_descending_sequential = true
      (0...digits.length - 1).each do |i|
        if digits[i + 1] != (digits[i] + 1) % 10
          is_ascending_sequential = false
        end
        if digits[i + 1] != (digits[i] - 1) % 10
          is_descending_sequential = false
        end
      end
      return true if is_ascending_sequential || is_descending_sequential
    end

    false
  end
end

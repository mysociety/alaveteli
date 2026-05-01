module User::Anonymisable
  extend ActiveSupport::Concern

  def anonymise!
    return if info_requests.none? && comments.none?

    current_name = read_attribute(:name)
    [current_name, *previous_names].each do |name|
      censor_rules.create!(text: name,
                           replacement: _('[Name Removed]'),
                           case_sensitive: false,
                           last_edit_editor: 'User#anonymise!',
                           last_edit_comment: 'User#anonymise!')
    end
  end
end

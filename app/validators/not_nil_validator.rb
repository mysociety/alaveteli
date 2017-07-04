# -*- encoding : utf-8 -*-
# Public: Validates that the specified attribute is not nil
#
# Examples
#
#   class Foo
#     validates :some_attr, not_nil: true
#   end
#
#   class Bar
#     validates :some_attr, not_nil: { message: 'Custom message'  }
#   end
class NotNilValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, message) if value.nil?
  end

  private

  def message
    options[:message] || _("can't be nil")
  end
end

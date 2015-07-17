# -*- encoding : utf-8 -*-
# Monkeypatch! activerecord/lib/active_record/validations.rb
# Method to remove individual error messages from an ActiveRecord.
module ActiveRecord
  class Errors
    def delete(key)
      @errors.delete(key)
    end
  end
end

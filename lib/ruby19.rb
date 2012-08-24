if RUBY_VERSION.to_f < 1.9
  class String
    def force_encoding(*args)
      self
    end
  end
else
  class String
    # @see syck/lib/syck/rubytypes.rb
    def is_binary_data?
      self.count("\x00-\x7F", "^ -~\t\r\n").fdiv(self.size) > 0.3 || self.index("\x00") unless self.empty?
    end
  end
end

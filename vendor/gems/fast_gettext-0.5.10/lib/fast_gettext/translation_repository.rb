module FastGettext
  # Responsibility:
  #  - decide which repository to choose from given input
  module TranslationRepository
    extend self

    # only single-word types supported atm (mytype works, MyType will not)
    def build(name, options)
      type = options[:type] || :mo
      class_name = type.to_s.capitalize
      unless FastGettext::TranslationRepository.constants.map{|c|c.to_s}.include?(class_name)
        require "fast_gettext/translation_repository/#{type}" 
      end
      eval(class_name).new(name,options)
    end
  end
end
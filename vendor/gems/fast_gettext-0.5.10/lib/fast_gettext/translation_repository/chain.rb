require 'fast_gettext/translation_repository/base'

module FastGettext
  module TranslationRepository
    # Responsibility:
    #  - delegate calls to members of the chain in turn
    #TODO cache should be expired after a repo was added
    class Chain < Base
      attr_accessor :chain

      def initialize(name,options={})
        super
        self.chain = options[:chain]
      end

      def available_locales
        chain.map{|c|c.available_locales}.flatten.uniq
      end

      def pluralisation_rule
        chain.each do |c|
          result = c.pluralisation_rule and return result
        end
        nil
      end

      def [](key)
        chain.each do |c|
          result = c[key] and return result
        end
        nil
      end

      def plural(*keys)
        chain.each do |c|
          result = c.plural(*keys)
          return result unless result.compact.empty?
        end
        []
      end
    end
  end
end
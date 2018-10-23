class Webhook
  module Base
    cattr_accessor :registered_handlers

    def self.process(type, data)
      handler = Webhook::Base.registered_handlers.find do |h|
        h[:type] == type && h[:if].call(data)
      end

      raise Webhook::UnhandledTypeError.new(type) unless handler

      handler[:klass].new(data).process
    end

    module ClassMethods
      def register(type, options = {})
        options[:type] = type
        options[:klass] = self
        options[:if] ||= ->(_data) { true }

        Webhook::Base.registered_handlers ||= []
        Webhook::Base.registered_handlers << options
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    attr_reader :data

    def initialize(data)
      @data = data
    end

    def process
      raise NotImplementedError
    end
  end
end

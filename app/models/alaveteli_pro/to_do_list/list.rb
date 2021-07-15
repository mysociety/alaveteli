module AlaveteliPro
  module ToDoList

    class List
      attr_accessor :user

      def initialize(user)
        @user = user
      end

      def items
        self.class.item_types.map { |item_type| item_type.new(user) }
      end

      def active_items
        items.select { |item| item.count > 0 }
      end

      private

      def self.item_types
        [ ToDoList::NewResponse,
          ToDoList::ExpiringEmbargo,
          ToDoList::OverdueRequest,
          ToDoList::VeryOverdueRequest ]
      end

    end
  end
end

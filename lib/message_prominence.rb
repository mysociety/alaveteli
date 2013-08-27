module MessageProminence

    def has_prominence(prominence_states)
        send :include, InstanceMethods
        cattr_accessor :prominence_states
        self.prominence_states = prominence_states
        validates_inclusion_of :prominence, :in => self.prominence_states
    end

    module InstanceMethods

        def user_can_view?(user)
            Ability.can_view_with_prominence?(self.prominence, self.info_request, user)
        end

    end
end


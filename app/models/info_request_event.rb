# models/info_request_event.rb:
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request_event.rb,v 1.1 2008-01-02 15:45:00 francis Exp $

class InfoRequestEvent < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :event_type
    validates_inclusion_of :event_type, :in => ['sent', 'resent']

    # We store YAML version of parameters in the database
    def params=(params)
        self.params_yaml = params.to_yaml
    end
    def params
        YAML.load(self.params_yaml)
    end

    # Used for sorting with the incoming/outgoing messages
    def sent_at
        created_at
    end

end



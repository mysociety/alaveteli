# app/controllers/body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: body_controller.rb,v 1.2 2007-10-30 18:52:27 francis Exp $

class BodyController < ApplicationController
    # XXX tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
    def show
        @public_bodies = PublicBody.find(:all,
            :conditions => [ "regexp_replace(replace(lower(short_name), ' ', '-'), '[^a-z0-9_-]', '', 'g') = ?", params[:simple_short_name] ])
        if @public_bodies.size > 1
            raise "Two bodies with the same simplified short name: " . params[:simple_short_name]
        end
        # If none found, then search the history of short names, and do a redirect
        if @public_bodies.size == 0
            @public_bodies = PublicBody.find(:all,
                :conditions => [ "id in (select public_body_id from public_body_versions where regexp_replace(replace(lower(short_name), ' ', '-'), '[^a-z0-9_-]', '', 'g') = ?)", params[:simple_short_name] ])
            if @public_bodies.size > 1
                raise "Two bodies with the same historical simplified short name: " . params[:simple_short_name]
            end
            redirect_to show_public_body_url(:simple_short_name => simplify_url_part(@public_bodies[0].short_name))
        end
        @public_body = @public_bodies[0]
    end

end

# app/controllers/body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: body_controller.rb,v 1.17 2008-09-13 15:35:37 francis Exp $

class BodyController < ApplicationController
    # XXX tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
    def show
        if MySociety::Format.simplify_url_part(params[:url_name]) != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name])
            return
        end

        @public_bodies = PublicBody.find(:all,
            :conditions => [ "url_name = ?", params[:url_name] ])
        if @public_bodies.size > 1
            raise "Two bodies with the same URL name: " . params[:url_name]
        end
        # If none found, then search the history of short names, and do a redirect
        if @public_bodies.size == 0
            @public_bodies = PublicBody.find(:all,
                :conditions => [ "id in (select public_body_id from public_body_versions where url_name = ?)", params[:url_name] ])
            if @public_bodies.size > 1
                raise "Two bodies with the same historical URL name: " . params[:url_name]
            end
            if @public_bodies.size == 0
                raise "None found" # XXX proper 404
            end
            redirect_to show_public_body_url(:url_name => @public_bodies[0].url_name)
        end
        @public_body = @public_bodies[0]

        @track_thing = TrackThing.create_track_for_public_body(@public_body)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]
    end

    def list
        @tag = params[:tag]
        if @tag.nil?
            @tag = "all"
            conditions = []
        elsif @tag == 'other'
            category_list = PublicBody.categories.map{|c| "'"+c+"'"}.join(",")
            conditions = ['(select count(*) from public_body_tags where public_body_tags.public_body_id = public_bodies.id
                and public_body_tags.name in (' + category_list + ')) = 0']
        elsif @tag.size == 1
            @tag.upcase!
            conditions = ['first_letter = ?', @tag]
        else
            conditions = ['(select count(*) from public_body_tags where public_body_tags.public_body_id = public_bodies.id
                and public_body_tags.name = ?) > 0', @tag]
        end
        @public_bodies = PublicBody.paginate(
            :order => "public_bodies.name", :page => params[:page], :per_page => 1000, # fit all councils on one page
            :conditions => conditions
            )
        if @tag.size == 1
            @description = "beginning with '" + @tag + "'"
        else
            @description = PublicBody.categories_by_tag[@tag]
            if @description.nil?
                @description = @tag
            end
        end
    end
end



# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HelpController, "when using help" do
    render_views

    it "shows the about page" do
        get :about
    end

    it "shows contact form" do
        get :contact
    end

    it "sends a contact message" do
        post :contact, { :contact => {
                :name => "Vinny Vanilli",
                :email => "vinny@localhost",
                :subject => "Why do I have such an ace name?",
                :message => "You really should know!!!\n\nVinny",
            }, :submitted_contact_form => 1
        }
        response.should redirect_to(:controller => 'general', :action => 'frontpage')

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        deliveries[0].body.should include("really should know")
        deliveries.clear
    end

    describe 'when requesting a page in a supported locale ' do

        before do
            # Prepend our fixture templates
            fixture_theme_path = File.join(Rails.root, 'spec', 'fixtures', 'theme_views', 'theme_one')
            controller.prepend_view_path fixture_theme_path
        end

        it 'should render the locale-specific template if available' do
            get :contact, {:locale => 'es'}
            response.body.should match('contáctenos theme one')
        end

    end


end


require File.dirname(__FILE__) + '/../spec_helper'

describe HelpController, "when using help" do
    integrate_views
  
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
    end

end


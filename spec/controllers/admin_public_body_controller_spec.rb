require File.dirname(__FILE__) + '/../spec_helper'

describe AdminPublicBodyController, "#route_for" do
  
  it "should map { :controller => 'admin_public_body', :action => 'list' } to /admin/body/list" do
    route_for(:controller => "admin_public_body", :action => "list").should == "/admin/body/list"
  end

end

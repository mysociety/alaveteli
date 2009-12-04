# This is a test of the monkey patches in lib/fcgi_fixes.rb

require File.dirname(__FILE__) + '/../spec_helper'

require 'railties/lib/fcgi_handler.rb'

describe "when doing FastCGI" do

  it "should have fixed dynamic FastCGI bug" do
    RailsFCGIHandler::SIGNALS['TERM'].should == :exit
  end

end


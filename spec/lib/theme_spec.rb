# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "theme_url_to_theme_name" do

  it "should deal with a typical bare repo URL" do
    url = 'git://wherever/blah-theme.git'
    theme_url_to_theme_name(url).should == 'blah-theme'
  end

  it "should deal with a typical bare repo URL with trailing slashes" do
    url = 'ssh://wherever/blah-theme.git//'
    theme_url_to_theme_name(url).should == 'blah-theme'
  end

  it "should deal with a typical non-bare repo URL" do
    url = '/home/whoever/themes/blah-theme'
    theme_url_to_theme_name(url).should == 'blah-theme'
  end

  it "should deal with a typical non-bare repo URL with a trailing slash" do
    url = '/home/whoever/themes/blah-theme/'
    theme_url_to_theme_name(url).should == 'blah-theme'
  end

end

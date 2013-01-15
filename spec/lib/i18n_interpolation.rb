# This is a test of the set_content_type monkey patch in
# lib/tmail_extensions.rb

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when using i18n" do

    it "should not complain if we're missing variables from the string" do
        result = _('Hello', :dip => 'hummus')
        result.should == 'Hello'
        result = _('Hello {{dip}}', :dip => 'hummus')
        result.should == 'Hello hummus'
    end

    it "should assume that simple translations are always html safe" do
      _("Hello").should be_html_safe
    end

end

describe "gettext_interpolate" do
    context "html unsafe string" do
        let(:string) { "Hello {{a}}" }

        it "should give an unsafe result" do
          result = gettext_interpolate(string, :a => "foo")
          result.should == "Hello foo"
          result.should_not be_html_safe
        end

        it "should give an unsafe result" do
          result = gettext_interpolate(string, :a => "foo".html_safe)
          result.should == "Hello foo"
          result.should_not be_html_safe
        end        
    end

    context "html safe string" do
        let(:string) { "Hello {{a}}".html_safe }

        it "should quote the input if it's unsafe" do
          result = gettext_interpolate(string, :a => "foo&")
          result.should == "Hello foo&amp;"
          result.should be_html_safe
        end

        it "should not quote the input if it's safe" do
          result = gettext_interpolate(string, :a => "foo&".html_safe)
          result.should == "Hello foo&"
          result.should be_html_safe
        end        
    end
end

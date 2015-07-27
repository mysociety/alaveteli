# -*- encoding : utf-8 -*-
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

describe "n_" do
  it "should return the translated singular" do
    FastGettext.should_receive(:n_).with("Apple", "Apples", 1).and_return("Apfel")
    n_("Apple", "Apples", 1).should == "Apfel"
  end

  it "should return the translated plural" do
    FastGettext.should_receive(:n_).with("Apple", "Apples", 3).and_return("Äpfel")
    n_("Apple", "Apples", 3).should == "Äpfel"
  end

  it "should return the translated singular interpolated" do
    FastGettext.should_receive(:n_).with("I eat {{count}} apple", "I eat {{count}} apples", 1).
      and_return("Ich esse {{count}} Apfel")
    n_("I eat {{count}} apple", "I eat {{count}} apples", 1, :count => 1).should == "Ich esse 1 Apfel"
  end

  it "should return the translated plural interpolated" do
    FastGettext.should_receive(:n_).with("I eat {{count}} apple", "I eat {{count}} apples", 3).
      and_return("Ich esse {{count}} Äpfel")
    n_("I eat {{count}} apple", "I eat {{count}} apples", 3, :count => 3).should == "Ich esse 3 Äpfel"
  end

  it "should always be html safe when there is no interpolation" do
    FastGettext.should_receive(:n_).with("Apple", "Apples", 1).and_return("Apfel")
    n_("Apple", "Apples", 1).should be_html_safe
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

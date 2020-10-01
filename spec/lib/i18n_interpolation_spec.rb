# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when using i18n" do

  it "should not complain if we're missing variables from the string" do
    result = _('Hello', :dip => 'hummus')
    expect(result).to eq('Hello')
    result = _('Hello {{dip}}', :dip => 'hummus')
    expect(result).to eq('Hello hummus')
  end

  it "should assume that simple translations are always html safe" do
    expect(_("Hello")).to be_html_safe
  end
end

describe 'n_' do
  before { AlaveteliLocalization.set_locales('de en', 'en') }

  it 'returns the translated singular' do
    AlaveteliLocalization.with_locale('de') do
      expect(n_('Apple', 'Apples', 1)).to eq('Apfel')
    end
  end

  it 'returns the translated plural' do
    AlaveteliLocalization.with_locale('de') do
      expect(n_('Apple', 'Apples', 3)).to eq('Äpfel')
    end
  end

  it 'returns the translated singular interpolated' do
    AlaveteliLocalization.with_locale('de') do
      expect(
        n_('I eat {{count}} apple', 'I eat {{count}} apples', 1, count: 1)
      ).to eq('Ich esse 1 Apfel')
    end
  end

  it 'returns the translated plural interpolated' do
    AlaveteliLocalization.with_locale('de') do
      expect(
        n_('I eat {{count}} apple', 'I eat {{count}} apples', 3, count: 3)
      ).to eq('Ich esse 3 Äpfel')
    end
  end

  it 'returns html safe string when there is no interpolation' do
    AlaveteliLocalization.with_locale('de') do
      expect(n_('Apple', 'Apples', 1)).to be_html_safe
    end
  end
end

describe "gettext_interpolate" do
  context "html unsafe string" do
    let(:string) { "Hello {{a}}" }

    it "should give an unsafe result" do
      result = gettext_interpolate(string, :a => "foo")
      expect(result).to eq("Hello foo")
      expect(result).not_to be_html_safe
    end

    it "should give an unsafe result" do
      result = gettext_interpolate(string, :a => "foo".html_safe)
      expect(result).to eq("Hello foo")
      expect(result).not_to be_html_safe
    end
  end

  context "html safe string" do
    let(:string) { "Hello {{a}}".html_safe }

    it "should quote the input if it's unsafe" do
      result = gettext_interpolate(string, :a => "foo&")
      expect(result).to eq("Hello foo&amp;")
      expect(result).to be_html_safe
    end

    it "should not quote the input if it's safe" do
      result = gettext_interpolate(string, :a => "foo&".html_safe)
      expect(result).to eq("Hello foo&")
      expect(result).to be_html_safe
    end
  end
end

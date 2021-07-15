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
  before { AlaveteliLocalization.set_locales('de en hr', 'en') }

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

  it 'handles count as strings' do
    FastGettext.pluralisation_rule = ->(n) { n > 1 }

    expect(n_('apple', 'apples', '1')).to eq('apple')
    expect(n_('apple', 'apples', '2')).to eq('apples')

    FastGettext.pluralisation_rule = nil
  end

  it 'handles locales with more than two pluralisation forms' do
    AlaveteliLocalization.with_locale('hr') do
      expect(
        n_('There is an apple', 'There are {{count}} apples', 1, count: 1)
      ).to eq('Postoji jabuka') # There is an apple

      expect(
        n_('There is an apple', 'There are {{count}} apples', 2, count: 2)
      ).to eq('Postoje 2 jabuke') # There are 2 apples

      expect(
        n_('There is an apple', 'There are {{count}} apples', 5, count: 5)
      ).to eq('Postoji 5 jabuka') # There are 5 apples
    end
  end

  it 'handles strings with more than two pluralisation forms' do
    FastGettext.pluralisation_rule = ->(n) { n - 1 }

    expect(n_('a', 'b', 'c', 'd', 1)).to eq('a')
    expect(n_('a', 'b', 'c', 'd', 2)).to eq('b')
    expect(n_('a', 'b', 'c', 'd', 3)).to eq('c')
    expect(n_('a', 'b', 'c', 'd', 4)).to eq('d')

    FastGettext.pluralisation_rule = nil
  end

  it 'handles interpolated strings with more than two pluralisation forms' do
    FastGettext.pluralisation_rule = ->(n) { n - 1 }

    expect(
      n_('a{{i}}', 'b{{i}}', 'c{{i}}', 'd{{i}}', 1, i: 1)
    ).to eq('a1')

    expect(
      n_('a{{i}}', 'b{{i}}', 'c{{i}}', 'd{{i}}', 2, i: 2)
    ).to eq('b2')

    expect(
      n_('a{{i}}', 'b{{i}}', 'c{{i}}', 'd{{i}}', 3, i: 3)
    ).to eq('c3')

    expect(
      n_('a{{i}}', 'b{{i}}', 'c{{i}}', 'd{{i}}', 4, i: 4)
    ).to eq('d4')

    FastGettext.pluralisation_rule = nil
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

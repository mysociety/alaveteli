# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminRawEmailsHelper do

  include AdminRawEmailsHelper

  describe '#address_list' do

    it 'formats a list of addresses' do
      list = %w(a@example.com
                b@example.net
                c@example.org)
      expect(address_list(list)).to eq(<<-EOF.squish)
      <code>a@example.com</code>,
      <code>b@example.net</code>,
      <code>c@example.org</code>
      EOF
    end

    it 'formats a single address' do
      expect(address_list('a@example.com')).to eq(%(<code>a@example.com</code>))
    end

    it 'ignores nils' do
      expect(address_list(nil)).to eq('')
      expect(address_list([nil])).to eq('')
    end

    it 'santises input' do
      expect(address_list('<script>bad</script>@example.com')).
        to eq('<code>&lt;script&gt;bad&lt;/script&gt;@example.com</code>')
    end

    it 'is html_safe' do
      expect(address_list('a@example.com')).to be_html_safe
    end

  end

end

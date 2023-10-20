require 'spec_helper'

RSpec.describe MailerHelper do
  include MailerHelper

  describe '#case_reference' do
    context 'with the default prefix' do
      subject { case_reference }
      it { is_expected.to match(/CASE\/\d{8}-[A-Z0-9]{4}/) }
    end

    context 'with a custom prefix' do
      subject { case_reference('HELP') }
      it { is_expected.to match(/HELP\/\d{8}-[A-Z0-9]{4}/) }
    end
  end
end

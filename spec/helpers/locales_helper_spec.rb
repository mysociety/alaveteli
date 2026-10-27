require 'spec_helper'

RSpec.describe LocalesHelper do
  include LocalesHelper

  before do
    AlaveteliLocalization.set_locales('en cy es', 'en')
    AlaveteliLocalization.set_session_locale('cy')
  end

  describe '#current_locale' do
    subject { current_locale }
    it { is_expected.to eq('cy') }
  end

  describe '#switchable_locales' do
    subject { switchable_locales }
    it { is_expected.to eq(%w[en es]) }
  end
end

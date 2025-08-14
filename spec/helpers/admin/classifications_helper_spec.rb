require 'spec_helper'

RSpec.describe Admin::ClassificationsHelper do
  include Admin::ClassificationsHelper

  describe '#classification_icon' do
    subject { classification_icon(classifiable) }

    let(:classifiable) do
      FactoryBot.build(:info_request, described_state: 'successful')
    end

    it { is_expected.to include('classification_icon--successful') }
    it { is_expected.to include('title="Successful"') }
  end
end

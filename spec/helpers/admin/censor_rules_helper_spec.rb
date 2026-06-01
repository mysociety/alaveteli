require 'spec_helper'

RSpec.describe Admin::CensorRulesHelper do
  include AdminHelper # Dependencies for `both_links`
  include Admin::CensorRulesHelper

  describe '#censor_rule_applies_to' do
    subject { censor_rule_applies_to(censor_rule) }

    context 'with an info_request censor rule' do
      let(:censor_rule) { FactoryBot.create(:info_request_censor_rule) }
      it { is_expected.to eq(both_links(censor_rule.censorable)) }
    end

    context 'with an public_body censor rule' do
      let(:censor_rule) { FactoryBot.create(:public_body_censor_rule) }
      it { is_expected.to eq(both_links(censor_rule.censorable)) }
    end

    context 'with a user censor rule' do
      let(:censor_rule) { FactoryBot.create(:user_censor_rule) }
      it { is_expected.to eq(both_links(censor_rule.censorable)) }
    end

    context 'with a global censor rule' do
      let(:censor_rule) { FactoryBot.create(:global_censor_rule) }
      it { is_expected.to eq('<strong>everything</strong>') }
    end
  end
end

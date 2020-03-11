require 'spec_helper'

RSpec.describe Project, type: :model, feature: :projects do
  subject(:project) { FactoryBot.build(:project) }

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires title' do
      project.title = nil
      is_expected.not_to be_valid
    end
  end
end

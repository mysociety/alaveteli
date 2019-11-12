require 'spec_helper'
require Rails.root.join('lib/yaml_compatibility')

RSpec.describe YAMLCompatibility do
  describe '.load' do
    subject(:output_hash) { described_class.load(content) }
    let(:hash) { YAML.load(yaml_compatibility_fixture('5_1')) }

    context 'with Rails 4.2 YAML file' do
      let(:content) { yaml_compatibility_fixture('4_2') }

      it 'correctly loads YAML file' do
        is_expected.to eq hash
      end
    end

    context 'with Rails 5.1 YAML file' do
      let(:content) { yaml_compatibility_fixture('5_1') }

      it 'correctly loads YAML file' do
        is_expected.to eq hash
      end
    end

    context 'YAML file with old PublicBodyTag class' do
      let(:content) { yaml_compatibility_fixture('public_body_tag') }

      it 'does not raise an error' do
        expect { output_hash }.to_not raise_error
      end
    end

    context 'YAML file with old TMail classes' do
      let(:content) { yaml_compatibility_fixture('tmail') }

      it 'does not raise an error' do
        expect { output_hash }.to_not raise_error
      end
    end
  end

  private

  def yaml_compatibility_fixture(file)
    load_file_fixture("yaml_compatibility_#{file}.yml")
  end
end

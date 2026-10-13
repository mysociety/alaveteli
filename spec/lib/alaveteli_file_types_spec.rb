require 'spec_helper'

RSpec.describe AlaveteliFileTypes do
  describe '.filename_to_mimetype' do
    it 'maps xlsm to the macro-enabled Excel type' do
      expect(described_class.filename_to_mimetype('report.xlsm')).
        to eq('application/vnd.ms-excel.sheet.macroenabled.12')
    end

    it 'maps docm to the macro-enabled Word type' do
      expect(described_class.filename_to_mimetype('report.docm')).
        to eq('application/vnd.ms-word.document.macroenabled.12')
    end
  end

  describe '.mimetype_to_extension' do
    it 'maps the macro-enabled Excel type back to xlsm' do
      expect(
        described_class.mimetype_to_extension(
          'application/vnd.ms-excel.sheet.macroenabled.12'
        )
      ).to eq('xlsm')
    end
  end
end

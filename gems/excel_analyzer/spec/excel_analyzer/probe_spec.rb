# frozen_string_literal: true

require "spec_helper"

RSpec.describe ExcelAnalyzer::Probe do
  include ExcelAnalyzer::Probe

  it "does not error if workbook has chartsheets" do
    xlsx = File.open(File.join(__dir__, "../fixtures/chartsheet.xlsx"))
    expect(probe(xlsx)).to be_a(Hash)
  end
end


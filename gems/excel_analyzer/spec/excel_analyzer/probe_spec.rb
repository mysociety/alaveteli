# frozen_string_literal: true

require "spec_helper"

RSpec.describe ExcelAnalyzer::Probe do
  include ExcelAnalyzer::Probe

  def fixture(filename)
    File.open(File.join(__dir__, "../fixtures/#{filename}"))
  end

  it "does not error if workbook has chartsheets" do
    xlsx = fixture("chartsheet.xlsx")
    expect(probe(xlsx)).to be_a(Hash)
  end

  it "does not error if workbook has hidden cols that intersect a blank row" do
    xlsx = fixture("hidden-cols-blank-row.xlsx")
    expect(probe(xlsx)).to be_a(Hash)
  end
end


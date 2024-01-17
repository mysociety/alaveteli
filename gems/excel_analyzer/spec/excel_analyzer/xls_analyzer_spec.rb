# frozen_string_literal: true

require "spec_helper"

RSpec.describe ExcelAnalyzer::XlsAnalyzer do
  describe ".accept?" do
    subject { ExcelAnalyzer::XlsAnalyzer.accept?(blob) }

    context "when the blob is an Excel file" do
      let(:blob) do
        fake_blob(content_type: ExcelAnalyzer::XlsAnalyzer::CONTENT_TYPE)
      end

      it { is_expected.to eq true }
    end

    context "when the blob is not an Excel file" do
      let(:blob) { fake_blob(content_type: "text/plain") }
      it { is_expected.to eq false }
    end
  end

  describe "#metadata" do
    let(:metadata) { ExcelAnalyzer::XlsAnalyzer.new(blob).metadata }

    context "when the blob is an Excel file with hidden data" do
      let(:blob) do
        fake_blob(io: File.open(File.join(__dir__, "../fixtures/suspect.xls")),
                  content_type: ExcelAnalyzer::XlsAnalyzer::CONTENT_TYPE)
      end

      it "detects external links" do
        expect(metadata[:excel][:external_links]).to eq true
      end

      it "detects hidden columns" do
        expect(metadata[:excel][:hidden_columns]).to eq true
      end

      it "detects hidden rows" do
        expect(metadata[:excel][:hidden_rows]).to eq true
      end

      it "detects hidden sheets" do
        expect(metadata[:excel][:hidden_sheets]).to eq true
      end

      it "detects pivot cache" do
        expect(metadata[:excel][:pivot_cache]).to eq true
      end
    end

    context "when the blob is an Excel file without hidden data" do
      let(:blob) do
        fake_blob(io: File.open(File.join(__dir__, "../fixtures/data.xls")),
                  content_type: ExcelAnalyzer::XlsAnalyzer::CONTENT_TYPE)
      end

      it "does not detect hidden data" do
        expect(metadata[:excel]).to eq(
          external_links: false,
          hidden_columns: false,
          hidden_rows: false,
          hidden_sheets: false,
          pivot_cache: false
        )
      end
    end

    context "when the blob is not an Excel file" do
      let(:blob) do
        fake_blob(io: File.open(File.join(__dir__, "../fixtures/plain.txt")),
                  content_type: "text/plain")
      end

      it "returns an error metadata" do
        expect(metadata[:excel]).to eq(error: "LibreOffice conversion failed")
      end
    end
  end

  private

  def fake_blob(io: nil, content_type:)
    dbl = double(content_type: content_type)
    allow(dbl).to receive(:open).and_yield(io)
    dbl
  end
end

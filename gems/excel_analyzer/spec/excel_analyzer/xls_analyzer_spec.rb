# frozen_string_literal: true

require "spec_helper"
require_relative "../support/helpers"

RSpec.describe ExcelAnalyzer::XlsAnalyzer do
  describe ".accept?" do
    subject { ExcelAnalyzer::XlsAnalyzer.accept?(blob) }

    context "when the blob is an Excel file" do
      let(:blob) { fake_blob(content_type: "application/vnd.ms-excel") }
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

      it "does not detect data model" do
        expect(metadata[:excel][:data_model]).to eq 0
      end

      it "detects external links" do
        expect(metadata[:excel][:external_links]).to eq 1
      end

      it "detects hidden columns" do
        expect(metadata[:excel][:hidden_columns]).to eq 2
      end

      it "detects hidden rows" do
        expect(metadata[:excel][:hidden_rows]).to eq 2
      end

      it "detects hidden sheets" do
        expect(metadata[:excel][:hidden_sheets]).to eq 1
      end

      it "detects named ranges" do
        expect(metadata[:excel][:named_ranges]).to eq 1
      end

      it "detects pivot cache" do
        expect(metadata[:excel][:pivot_cache]).to eq 1
      end
    end

    context "when the blob is an Excel file without hidden data" do
      let(:blob) do
        fake_blob(io: File.open(File.join(__dir__, "../fixtures/data.xls")),
                  content_type: ExcelAnalyzer::XlsAnalyzer::CONTENT_TYPE)
      end

      it "does not detect hidden data" do
        expect(metadata[:excel]).to eq(
          data_model: 0,
          external_links: 0,
          hidden_columns: 0,
          hidden_rows: 0,
          hidden_sheets: 0,
          named_ranges: 0,
          pivot_cache: 0
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
end

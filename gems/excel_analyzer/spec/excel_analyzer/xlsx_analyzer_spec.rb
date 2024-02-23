# frozen_string_literal: true

require "spec_helper"
require_relative "../support/helpers"

RSpec.describe ExcelAnalyzer::XlsxAnalyzer do
  describe ".accept?" do
    subject { ExcelAnalyzer::XlsxAnalyzer.accept?(blob) }

    context "when the blob is an Excel file" do
      let(:content_type) do
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      end

      let(:blob) { fake_blob(content_type: content_type) }
      it { is_expected.to eq true }
    end

    context "when the blob is not an Excel file" do
      let(:blob) { fake_blob(content_type: "text/plain") }
      it { is_expected.to eq false }
    end
  end

  describe "#metadata" do
    around do |example|
      original_callback = ExcelAnalyzer.on_hidden_metadata
      ExcelAnalyzer.on_hidden_metadata = ->(blob) {}
      example.call
      ExcelAnalyzer.on_hidden_metadata = original_callback
    end

    let(:metadata) { ExcelAnalyzer::XlsxAnalyzer.new(blob).metadata }

    context "when the blob is an Excel file with hidden data" do
      let(:blob) do
        fake_blob(io: File.open(File.join(__dir__, "../fixtures/suspect.xlsx")),
                  content_type: ExcelAnalyzer::XlsxAnalyzer::CONTENT_TYPE)
      end

      it "detects data model" do
        # stub as creating a fixture file with a data model in LibreOffice is
        # impossible
        file = Zip::File.new(blob.io.path, create: false)

        allow(file).to receive("glob").with(any_args).and_call_original
        allow(file).to receive("glob").with("xl/model/*").and_return([double])
        allow(ExcelAnalyzer::Metadata).to receive(:new).and_return(
          ExcelAnalyzer::Metadata.new(file)
        )

        expect(metadata[:excel][:data_model]).to eq 1

        file.close
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

      it "does not call on_hidden_metadata callback" do
        expect(ExcelAnalyzer.on_hidden_metadata).to receive(:call)
        metadata
      end
    end

    context "when the blob is an Excel file without hidden data" do
      let(:blob) do
        fake_blob(io: File.open(File.join(__dir__, "../fixtures/data.xlsx")),
                  content_type: ExcelAnalyzer::XlsxAnalyzer::CONTENT_TYPE)
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

      it "does not call on_hidden_metadata callback" do
        expect(ExcelAnalyzer.on_hidden_metadata).to_not receive(:call)
        metadata
      end
    end

    context "when the blob is not an Excel file" do
      let(:blob) do
        fake_blob(io: File.open(File.join(__dir__, "../fixtures/plain.txt")),
                  content_type: "text/plain")
      end

      it "returns an error metadata" do
        expect(metadata[:excel]).to eq(
          error: "Zip end of central directory signature not found"
        )
      end

      it "does not call on_hidden_metadata callback" do
        expect(ExcelAnalyzer.on_hidden_metadata).to_not receive(:call)
        metadata
      end
    end
  end
end

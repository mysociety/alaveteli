# frozen_string_literal: true

require "spec_helper"
require_relative "../support/helpers"

RSpec.describe ExcelAnalyzer::EmlAnalyzer do
  describe ".accept?" do
    subject { ExcelAnalyzer::EmlAnalyzer.accept?(blob) }

    context "when the blob is an email" do
      let(:blob) { fake_blob(content_type: "message/rfc822") }
      it { is_expected.to eq true }
    end

    context "when the blob is not an email" do
      let(:blob) { fake_blob(content_type: "text/plain") }
      it { is_expected.to eq false }
    end
  end

  describe "#metadata" do
    let(:mail) do
      Mail.new { add_file File.join(__dir__, "../fixtures/data.xls") }
    end

    let(:io) { double(:File, path: "blob/path") }
    let(:blob) { fake_blob(io: io, content_type: "message/rfc822") }

    subject(:metadata) { ExcelAnalyzer::EmlAnalyzer.new(blob).metadata }

    before { allow(Mail).to receive(:read).with("blob/path").and_return(mail) }

    it { is_expected.to include(content_types: ["application/vnd.ms-excel"]) }
  end
end

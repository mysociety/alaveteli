# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActsAsXapian do

  before { update_xapian_index }

  describe '.update_index' do

    it 'processes jobs that were queued after a job that errors' do
      job1, job2 = Array.new(2) do |i|
        body = FactoryBot.create(:public_body)
        body.xapian_mark_needs_index
        ActsAsXapian::ActsAsXapianJob.
          find_by(model: 'PublicBody', model_id: body.id)
      end

      # and_raise(StandardError) here to simulate a problem when extracting the
      # data to index
      allow(ActsAsXapian).
        to receive(:run_job).with(job1, any_args).and_raise(StandardError)

      # and_call_original here so that the run_job finishes and destroys the job
      allow(ActsAsXapian).
        to receive(:run_job).with(job2, any_args).and_call_original

      # Mute STDERR while we call update_index as we know we're going to get
      # output on STDERR when job1 fails
      RSpec::Mocks.with_temporary_scope do
        allow(STDERR).to receive(:puts)
        ActsAsXapian.update_index
      end

      # Both jobs should be destroyed after the run – we've either indexed it
      # successfully and destroyed the job, or we've failed to index, sent an
      # error message and removed the job to prevent multiple failed retries.
      expect { job1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { job2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

end

describe ActsAsXapian::FailedJob do
  let(:error) { StandardError.new('Testing the error handling') }
  let(:model_data) { { model: 'PublicBody', model_id: 7 } }
  let(:failed_job) { described_class.new(1, error, model_data) }

  describe '.new' do

    it 'requires a job_id' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'requires an error' do
      expect { described_class.new(1) }.to raise_error(ArgumentError)
    end

    it 'sets model_data to an empty hash by default' do
      expect(described_class.new(1, error).model_data).to eq({})
    end

  end

  describe '#job_id' do

    it 'returns the job_id' do
      expect(failed_job.job_id).to eq(1)
    end

  end

  describe '#error' do

    it 'returns the error' do
      expect(failed_job.error).to eq(error)
    end

  end

  describe '#model_data' do

    it 'returns the model_data' do
      expect(failed_job.model_data).to eq(model_data)
    end

  end

  describe '#full_message' do

    it 'returns a message suitable for the exception notification' do
      error.set_backtrace(%w(BACKTRACE_L1 BACKTRACE_L2))

      msg = <<-EOF.strip_heredoc.chomp
      FAILED ActsAsXapian.update_index job 1 StandardError model PublicBody id 7.

      StandardError: Testing the error handling.

      This job will be removed from the queue. Once the underlying problem is fixed, manually re-index the model record.

      You can do this in a rails console with `PublicBody.find(7).xapian_mark_needs_index`.

      ---------
      Backtrace
      ---------

      BACKTRACE_L1
      BACKTRACE_L2
      EOF

      expect(failed_job.full_message).to eq(msg)
    end

  end

  describe '#error_backtrace' do

    it 'returns the error backtrace' do
      error.set_backtrace(%w(BACKTRACE_L1 BACKTRACE_L2))
      expect(failed_job.error_backtrace).to eq("BACKTRACE_L1\nBACKTRACE_L2")
    end

  end

  describe '#job_info' do

    context 'with full job info' do
      let(:failed_job) { described_class.new(1, error, model_data) }

      it 'includes information about the model being processed' do
        msg = <<-EOF.squish
        FAILED ActsAsXapian.update_index job 1 StandardError model PublicBody
        id 7.
        EOF
        expect(failed_job.job_info).to eq(msg)
      end
    end

    context 'without the model name' do
      let(:model_data) { { model_id: 7, model: nil } }
      let(:failed_job) { described_class.new(1, error, model_data) }

      it 'includes information about the model being processed' do
        msg = 'FAILED ActsAsXapian.update_index job 1 StandardError id 7.'
        expect(failed_job.job_info).to eq(msg)
      end
    end

    context 'without the model id' do
      let(:model_data) { { model_id: nil, model: 'PublicBody' } }
      let(:failed_job) { described_class.new(1, error, model_data) }

      it 'includes information about the model being processed' do
        msg = <<-EOF.squish
        FAILED ActsAsXapian.update_index job 1 StandardError model PublicBody.
        EOF
        expect(failed_job.job_info).to eq(msg)
      end
    end

    context 'without any model data' do
      let(:failed_job) { described_class.new(1, error) }

      it 'just includes information about the job' do
        msg = 'FAILED ActsAsXapian.update_index job 1 StandardError.'
        expect(failed_job.job_info).to eq(msg)
      end
    end
  end

end

describe ActsAsXapian::Search do

  describe "#words_to_highlight" do

    before :all do
      get_fixtures_xapian_index
    end

    before do
      @alice = FactoryBot.create(:public_body, :name => 'alice')
      update_xapian_index
    end

    after do
      @alice.destroy
      update_xapian_index
    end

    it "should return a list of words used in the search" do
      s = ActsAsXapian::Search.new([PublicBody], "albatross words", :limit => 100)
      expect(s.words_to_highlight).to eq(["albatross", "word"])
    end

    it "should remove any operators" do
      s = ActsAsXapian::Search.new([PublicBody], "albatross words tag:mice", :limit => 100)
      expect(s.words_to_highlight).to eq(["albatross", "word"])
    end

    it "should separate punctuation" do
      s = ActsAsXapian::Search.new([PublicBody], "The doctor's patient", :limit => 100)
      expect(s.words_to_highlight).to eq(["the", "doctor", "patient"].sort)
    end

    it "should handle non-ascii characters" do
      s = ActsAsXapian::Search.new([PublicBody], "adatigénylés words tag:mice", :limit => 100)
      expect(s.words_to_highlight).to eq(["adatigénylé", "word"])
    end

    it "should ignore stopwords" do
      s = ActsAsXapian::Search.new([PublicBody], "department of humpadinking", :limit => 100)
      expect(s.words_to_highlight).not_to include('of')
    end

    it "uses stemming" do
      s = ActsAsXapian::Search.new([PublicBody], 'department of humpadinking', :limit => 100)
      expect(s.words_to_highlight).to eq(["depart", "humpadink"])
    end

    it "doesn't stem proper nouns" do
      s = ActsAsXapian::Search.new([PublicBody], 'department of Humpadinking', :limit => 1)
      expect(s.words_to_highlight).to eq(["depart", "humpadinking"])
    end

    it "includes the original search terms if requested" do
      s = ActsAsXapian::Search.new([PublicBody], 'boring', :limit => 1)
      expect(s.words_to_highlight(:include_original => true)).to eq(['bore', 'boring'])
    end

    it "does not return duplicate terms" do
      s = ActsAsXapian::Search.new([PublicBody], 'boring boring', :limit => 1)
      expect(s.words_to_highlight).to eq(['bore'])
    end

    context 'the :regex option' do

      it 'wraps each words in a regex that matches the full word' do
        expected = [/\b(albatross)\b/iu]
        s = ActsAsXapian::Search.new([PublicBody], 'Albatross', :limit => 1)
        expect(s.words_to_highlight(:regex => true)).to eq(expected)
      end

      it 'wraps each stem in a regex' do
        expected = [/\b(depart)\w*\b/iu]
        s = ActsAsXapian::Search.new([PublicBody], 'department', :limit => 1)
        expect(s.words_to_highlight(:regex => true)).to eq(expected)
      end

    end
  end

  describe '#spelling_correction' do

    before :all do
      load_raw_emails_data
      get_fixtures_xapian_index
    end

    before do
      @alice = FactoryBot.create(:public_body, :name => 'alice')
      @bob = FactoryBot.create(:public_body, :name => 'bôbby')
      update_xapian_index
    end

    after do
      @alice.destroy
      @bob.destroy
      update_xapian_index
    end

    it 'returns a UTF-8 encoded string' do
      s = ActsAsXapian::Search.new([PublicBody], "alece", :limit => 100)
      expect(s.spelling_correction).to eq("alice")
      if s.spelling_correction.respond_to? :encoding
        expect(s.spelling_correction.encoding.to_s).to eq('UTF-8')
      end
    end

    it 'handles non-ASCII characters' do
      s = ActsAsXapian::Search.new([PublicBody], "bobby", :limit => 100)
      expect(s.spelling_correction).to eq("bôbby")
    end

  end

end

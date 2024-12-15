require 'spec_helper'
require 'external_command'

RSpec.describe 'when importing mail logs into the application' do
  around do |example|
    ENV['DISABLE_DEPRECATION_WARNINGS'] = 'true'
    example.call
    ENV['DISABLE_DEPRECATION_WARNINGS'] = nil
  end

  def load_mail_server_logs_test(log_file = nil)
    Dir.chdir Rails.root do
      ExternalCommand.new('script/load-mail-server-logs', *log_file).run
    end
  end

  context 'without log file argument' do
    it 'should not produce any output and should return a 0 code' do
      r = load_mail_server_logs_test
      expect(r.status).to eq(0)
      expect(r.err).to eq('')
      expect(r.out).to eq('')
    end
  end

  context 'with log file' do
    it 'should not produce any output and should return a 0 code' do
      log = file_fixture_name('exim-mainlog-2016-04-28')
      r = load_mail_server_logs_test(log.to_s)
      expect(r.status).to eq(0)
      expect(r.err).to eq('')
      expect(r.out).to eq('')
    end
  end

  context 'with missing log file' do
    it 'should output no such file error' do
      r = load_mail_server_logs_test('missing')
      expect(r.err).to include('No such file or directory')
    end
  end
end

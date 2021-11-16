require 'spec_helper'

RSpec.describe DeeplyNestedParams do
  let(:env) { Rack::MockRequest.env_for }
  let(:app) { -> (_env) { [200, {}, ['success']] } }

  subject { DeeplyNestedParams.new(app) }

  it 'returns 200 response' do
    status, _headers, _response = subject.call(env)
    expect(status).to eq(200)
  end

  context 'if Rack::Utils.parse_query raises an RangeError' do
    before do
      allow(Rack::Utils).to receive(:parse_query).and_raise(RangeError)
    end

    it 'returns 400 response' do
      status, _headers, _response = subject.call(env)
      expect(status).to eq(400)
    end
  end
end

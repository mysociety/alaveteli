require 'spec_helper'

RSpec.describe "fetch_url" do
  let(:controller) { double(ApplicationController) }
  let(:uri) { "http://example.com/feed" }

  before do
    stub_request(:get, uri)
  end

  it "should send a default timeout of 60 seconds" do
    expect(Net::HTTP).to receive(:start).
      with('example.com', 80, hash_including(read_timeout: 60)).
      and_call_original
    controller.send(:fetch_url, uri)
  end

  it "should allow the timeout out be overridden" do
    expect(Net::HTTP).to receive(:start).
      with('example.com', 80, hash_including(read_timeout: 100)).
      and_call_original
    controller.send(:fetch_url, uri, timeout: 100)
  end

  it "returns the stripped response body" do
    stub_request(:get, uri).to_return(body: " feed\n")
    expect(controller.send(:fetch_url, uri)).to eq('feed')
  end

  it "returns an empty string if the URL can't be fetched" do
    stub_request(:get, uri).to_return(status: 404)
    expect(controller.send(:fetch_url, uri)).to eq('')
  end

  it "sends a notification in a request context" do
    stub_request(:get, uri).to_return(status: [404, 'Not Found'])
    allow(AlaveteliConfiguration).to receive(:exception_notifications_from).
      and_return('from@example.com')
    allow(AlaveteliConfiguration).to receive(:exception_notifications_to).
      and_return('to@example.com')
    allow(controller).to receive(:request).and_return(double(env: {}))

    expect(ExceptionNotifier).to receive(:notify_exception).with(
      an_instance_of(FetchURLError).and(
        having_attributes(
          message: "Unable to open third-party URL #{uri}: 404 Not Found"
        )
      ),
      env: {}
    )
    controller.send(:fetch_url, uri)
  end
end

RSpec.describe "fetch_url!" do
  let(:controller) { double(ApplicationController) }
  let(:uri) { "http://example.com/feed" }

  def fetch_url!(url)
    controller.send(:fetch_url!, url)
  end

  it "fetches HTTPS URLs" do
    stub_request(:get, 'https://example.com/feed').to_return(body: 'feed')
    expect(fetch_url!('https://example.com/feed')).to eq('feed')
  end

  it "sets the body encoding from the response charset" do
    stub_request(:get, uri).to_return(
      body: 'feed'.b,
      headers: { 'Content-Type' => 'text/xml; charset=utf-8' }
    )
    expect(fetch_url!(uri).encoding).to eq(Encoding::UTF_8)
  end

  it "reads text without a charset as UTF-8" do
    stub_request(:get, uri).to_return(
      body: 'Día de Año Nuevo'.b,
      headers: { 'Content-Type' => 'text/calendar' }
    )
    expect(fetch_url!(uri)).to eq('Día de Año Nuevo')
  end

  it "keeps other bodies without a charset as binary" do
    stub_request(:get, uri).to_return(
      body: 'data'.b, headers: { 'Content-Type' => 'application/gzip' }
    )
    expect(fetch_url!(uri).encoding).to eq(Encoding::BINARY)
  end

  it "follows redirects" do
    stub_request(:get, uri).
      to_return(status: 302, headers: { 'Location' => '/moved' })
    stub_request(:get, 'http://example.com/moved').to_return(body: 'feed')
    expect(fetch_url!(uri)).to eq('feed')
  end

  it "stops following redirects after 5" do
    stub_request(:get, uri).
      to_return(status: 302, headers: { 'Location' => uri })
    expect { fetch_url!(uri) }.
      to raise_error(FetchURLError, /Too many redirects/)
    expect(a_request(:get, uri)).to have_been_made.times(6)
  end

  it "raises an error for a redirect without a location" do
    stub_request(:get, uri).to_return(status: [300, 'Multiple Choices'])
    expect { fetch_url!(uri) }.
      to raise_error(FetchURLError, '300 Multiple Choices')
  end

  it "refuses to follow a redirect to a local file" do
    stub_request(:get, uri).
      to_return(status: 302, headers: { 'Location' => 'file:///etc/passwd' })
    expect { fetch_url!(uri) }.to raise_error(FetchURLError, /Unsupported URL/)
  end

  it "refuses to follow a redirect from HTTPS to HTTP" do
    stub_request(:get, 'https://example.com/feed').
      to_return(status: 302, headers: { 'Location' => uri })
    expect { fetch_url!('https://example.com/feed') }.
      to raise_error(FetchURLError, /Refused redirect/)
  end

  it "raises an error with the response for an unsuccessful response" do
    stub_request(:get, uri).to_return(status: [401, 'Unauthorized'])
    expect { fetch_url!(uri) }.
      to raise_error(FetchURLError, '401 Unauthorized') do |e|
        expect(e.response).to be_a(Net::HTTPUnauthorized)
      end
  end

  it "raises an error if the connection fails" do
    stub_request(:get, uri).to_raise(Errno::ECONNREFUSED)
    expect { fetch_url!(uri) }.to raise_error(FetchURLError)
  end

  it "raises an error if the request times out" do
    stub_request(:get, uri).to_timeout
    expect { fetch_url!(uri) }.to raise_error(FetchURLError)
  end

  it "refuses to run a command" do
    expect { fetch_url!('|id') }.to raise_error(FetchURLError)
  end

  it "refuses to read a local file" do
    expect { fetch_url!('/etc/passwd') }.
      to raise_error(FetchURLError, /Unsupported URL/)
  end

  it "refuses a URL without a host" do
    expect { fetch_url!('http:/feed') }.
      to raise_error(FetchURLError, /Unsupported URL/)
  end
end

RSpec.describe "quietly_try_to_open" do
  let(:controller) { double(ApplicationController) }
  let(:uri) { "http://example.com/feed" }

  it "forwards to fetch_url with a deprecation warning" do
    allow(controller).to receive(:fetch_url).
      with(uri, timeout: 100).and_return('feed')
    expect(controller).to receive(:warn).with(/DEPRECATION/)
    expect(controller.send(:quietly_try_to_open, uri, 100)).to eq('feed')
  end
end

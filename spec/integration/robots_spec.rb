require 'spec_helper'

RSpec.describe 'robots.txt', type: :request do
  before { get '/robots.txt' }

  it 'is served by the application rather than as a static file' do
    expect(response).to be_successful
    expect(response.media_type).to eq 'text/plain'
  end

  it 'is reachable at the path crawlers look for' do
    expect(robots_path).to eq '/robots.txt'
  end

  it 'declares the rules crawlers need' do
    expect(response.body).to start_with '# See https://www.robotstxt.org'
    expect(response.body).to include 'User-agent: *'
  end

  it 'disallows the paths which are expensive to crawl' do
    expect(response.body).to include 'Disallow: */search?*'
  end

  it 'allows attachments while disallowing their parent responses' do
    allow_rule = 'Allow: */request/*/response/*/attach/*'
    disallow_rule = 'Disallow: */request/*/response/*'

    expect(response.body).to include allow_rule
    expect(response.body).to include disallow_rule

    # The carve-out only works if it precedes the rule it carves out of.
    expect(response.body.index(allow_rule)).
      to be < response.body.index(disallow_rule)
  end

  # `*/tor*` blocked the /tor page but also every authority whose slug begins
  # "tor" - Torfaen, Torbay, Torridge.
  it 'blocks the tor page without blocking authorities named after it' do
    expect(response.body).to include 'Disallow: */tor$'
    expect(response.body).to_not include 'Disallow: */tor*'
  end

  it 'renders without the site layout' do
    expect(response.body).to_not include '<html'
  end

  it 'renders the template rather than leaking its markup' do
    expect(response.body).to_not include '<%'
  end
end

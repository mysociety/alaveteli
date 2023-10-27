require 'spec_helper'

RSpec.describe 'routing redirects', type: :request do
  it 'routes numerical request route to URL title route' do
    get('/request/105')
    expect(response).to redirect_to('/request/the_cost_of_boring')
  end

  it 'redirects numerical request routes with locales' do
    get('/fr/request/105')
    expect(response).to redirect_to('/fr/request/the_cost_of_boring')

    get('/en_GB/request/105')
    expect(response).to redirect_to('/en_GB/request/the_cost_of_boring')
  end

  it 'routes numerical request member routes to URL title member routes' do
    get('/request/105/followups/new')
    expect(response).to redirect_to('/request/the_cost_of_boring/followups/new')
  end
end

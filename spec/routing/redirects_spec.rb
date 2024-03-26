require 'spec_helper'

RSpec.describe 'routing redirects', type: :request do
  it 'routes numerical request route to URL title route' do
    get('/request/105')
    expect(response).to redirect_to('/request/the_cost_of_boring')
  end

  it 'routes numerical format request route to URL title format route' do
    get('/request/105.json')
    expect(response).to redirect_to('/request/the_cost_of_boring.json')
  end

  it 'routes numerical request member routes to URL title member routes' do
    get('/request/105/followups/new')
    expect(response).to redirect_to('/request/the_cost_of_boring/followups/new')

    get('/request/105/report/new')
    expect(response).to redirect_to('/request/the_cost_of_boring/report/new')

    get('/request/105/widget')
    expect(response).to redirect_to('/request/the_cost_of_boring/widget')

    get('/request/105/widget/new')
    expect(response).to redirect_to('/request/the_cost_of_boring/widget/new')
  end

  it 'routes numerical request attachment routes to URL title attachment routes' do
    get('/request/105/response/1/attach/2/filename.txt')
    expect(response).to redirect_to(
      '/request/the_cost_of_boring/response/1/attach/2/filename.txt'
    )

    get('/request/105/response/1/attach/html/2/filename.txt.html')
    expect(response).to redirect_to(
      '/request/the_cost_of_boring/response/1/attach/html/2/filename.txt.html'
    )
  end

  it 'redirects prefixed request routes to member routes' do
    get('/details/request/the_cost_of_boring')
    expect(response).to redirect_to('/request/the_cost_of_boring/details')

    get('/similar/request/the_cost_of_boring')
    expect(response).to redirect_to('/request/the_cost_of_boring/similar')

    get('/upload/request/the_cost_of_boring')
    expect(response).to redirect_to('/request/the_cost_of_boring/upload')

    get('/annotate/request/the_cost_of_boring')
    expect(response).to redirect_to('/request/the_cost_of_boring/annotate')

    get('/track/request/the_cost_of_boring')
    expect(response).to redirect_to('/request/the_cost_of_boring/track')

    get('/feed/request/the_cost_of_boring')
    expect(response).to redirect_to('/request/the_cost_of_boring/feed')

    get('/categorise/request/the_cost_of_boring')
    expect(response).to redirect_to('/request/the_cost_of_boring/categorise')
  end

  it 'redirects locale paths to locale parameter' do
    get('/fr')
    expect(response).to redirect_to('/?locale=fr')

    get('/en_GB')
    expect(response).to redirect_to('/?locale=en_GB')

    get('/fr/help/about')
    expect(response).to redirect_to('/help/about?locale=fr')

    get('/en_GB/help/about')
    expect(response).to redirect_to('/help/about?locale=en_GB')
  end

  it 'redirects to remove locale parameter' do
    get('/?locale=fr')
    expect(response).to redirect_to('/')

    get('/?locale=en_GB')
    expect(response).to redirect_to('/')

    get('/help/about?locale=fr')
    expect(response).to redirect_to('/help/about')

    get('/help/about?locale=en_GB')
    expect(response).to redirect_to('/help/about')
  end

  it 'redirects old pro request routes', feature: :alaveteli_pro do
    get('/alaveteli_pro/info_requests/my-request')
    expect(response).to redirect_to('/request/my-request')

    get('/alaveteli_pro/info_requests/new')
    expect(response).to_not redirect_to('/request/new')
  end

  it 'redirects from alaveteli_pro urls to pro urls', feature: :alaveteli_pro do
    get('/alaveteli_pro')
    expect(response).to redirect_to('/pro/dashboard')

    get('/alaveteli_pro/pricing')
    expect(response).to redirect_to('/pro/pricing')

    get('/alaveteli_pro/embargoes')
    expect(response).to redirect_to('/pro/embargoes')

    get('/alaveteli_pro/embargoes/1')
    expect(response).to redirect_to('/pro/embargoes/1')
  end
end

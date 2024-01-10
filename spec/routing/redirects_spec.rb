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

  it 'redirects numerical request routes with locales' do
    get('/fr/request/105')
    expect(response).to redirect_to('/fr/request/the_cost_of_boring')

    get('/en_GB/request/105')
    expect(response).to redirect_to('/en_GB/request/the_cost_of_boring')
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

  it 'redirects prefixed request routes with locales' do
    get('/fr/details/request/the_cost_of_boring')
    expect(response).to redirect_to('/fr/request/the_cost_of_boring/details')

    get('/en_GB/details/request/the_cost_of_boring')
    expect(response).to redirect_to('/en_GB/request/the_cost_of_boring/details')
  end
end

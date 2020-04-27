RSpec.shared_examples 'adding classification message action' do
  let(:info_request) { FactoryBot.create(:info_request) }

  before do
    session[:user_id] = info_request.user_id
  end

  it 'assigns the info_request to the view' do
    get :message, params: {
      url_title: info_request.url_title,
      described_state: 'error_message'
    }
    expect(assigns[:info_request]).to eq info_request
  end

  it 'assigns the described state to the view' do
    get :message, params: {
      url_title: info_request.url_title,
      described_state: 'error_message'
    }
    expect(assigns[:described_state]).to eq 'error_message'
  end

  it 'assigns the title to the view' do
    get :message, params: {
      url_title: info_request.url_title,
      described_state: 'error_message'
    }
    expect(assigns[:title]).to eq "I've received an error message"
  end
end

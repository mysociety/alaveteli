RSpec.shared_examples 'adding classification message action' do
  let(:info_request) { FactoryBot.create(:info_request) }

  def run_action
    get :message, params: {
      url_title: info_request.url_title,
      described_state: 'error_message'
    }
  end

  before do
    session[:user_id] = info_request.user_id
  end

  it 'assigns the info_request to the view' do
    run_action
    expect(assigns[:info_request]).to eq info_request
  end

  it 'assigns the described state to the view' do
    run_action
    expect(assigns[:described_state]).to eq 'error_message'
  end

  it 'assigns the title to the view' do
    run_action
    expect(assigns[:title]).to eq "I've received an error message"
  end
end

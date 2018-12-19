require 'spec_helper'

describe 'admin_general/_to_do_list.html.erb' do

  describe 'handling requests in an admin_required state' do
    let(:items) { [ request ] }

    def render_errors(items)
      render template: 'admin_general/_to_do_list',
             locals: { id: 'error-messages',
                       parent: 'public-request-things-to-do',
                       items: items,
                       label: 'Fix these delivery and other errors' }
    end

    shared_examples_for 'showing requests in an error state' do

      it 'renders the error-messages section' do
        render_errors(items)
        expect(rendered).to include('Fix these delivery and other errors')
      end

      it 'shows "None given" if there is no user message' do
        original_params = request.last_event.params
        allow(request.last_event).
          to receive(:params).
            and_return(params.delete_if { |key| key == :message } )
        render_errors(items)
        expect(rendered).to include('None given')
      end

      it 'shows the user message when there is one' do
        render_errors(items)
        expect(rendered).to include('Useful info')
      end

    end

    context 'request marked by requester as containing an error' do
      let(:request) { FactoryBot.create(:error_message_request) }
      it_behaves_like 'showing requests in an error state'
    end

    context 'request reported by requester as requiring admin attention' do
      let(:request) { FactoryBot.create(:requires_admin_request) }
      it_behaves_like 'showing requests in an error state'
    end

    context 'someone used the "Report request" button to flag the request' do
      let(:request) { FactoryBot.create(:attention_requested_request) }
      it_behaves_like 'showing requests in an error state'
    end

  end

end

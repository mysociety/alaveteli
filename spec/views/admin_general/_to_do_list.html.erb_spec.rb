require 'spec_helper'

describe 'admin_general/_to_do_list.html.erb' do

  describe 'handling requests in an admin_required state' do
    let(:items) { [request] }

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

      it 'shows the user message when there is one' do
        render_errors(items)
        expect(rendered).to include('Useful info')
      end

      context 'without user message' do
        let(:request) { FactoryBot.create(:blank_message_request) }

        it 'shows "None given"' do
          render_errors(items)
          expect(rendered).to include('None given')
        end
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

      it 'shows the reason given for the request being reported' do
        render_errors(items)
        expect(rendered).to include('Not a valid request')
      end
    end

    context 'the message send failed due to a network error' do
      let(:request) do
        FactoryBot.create(:failed_sent_request_event).info_request
      end

      it 'describes an error message rather than a user message' do
        render_errors(items)
        expect(rendered).to include('Reason')
      end

      it 'shows the reason given for the failed send' do
        render_errors(items)
        expect(rendered).to include('Connection timed out')
      end
    end

    context 'comment reported as requiring admin attention' do
      let(:request) { FactoryBot.create(:error_message_request) }

      let(:comment) do
        FactoryBot.create(:attention_requested_comment,
                          reason: 'Annotation contains defamatory material',
                          message: request.last_event.params[:message],
                          info_request: request)
      end

      let(:items) { [comment] }

      it_behaves_like 'showing requests in an error state'

      it 'shows the reason given for the comment being reported' do
        render_errors(items)
        expect(rendered).to include('Annotation contains defamatory material')
      end
    end

  end

end

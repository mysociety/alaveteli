require 'spec_helper'

RSpec.describe AttachmentsController, type: :controller do
  before do
    allow(@controller).to receive(:foi_fragment_cache_write)
  end

  let(:request_prominence) { 'normal' }
  let(:message_prominence) { 'normal' }
  let(:attachment_prominence) { 'normal' }

  let(:info_request) do
    FactoryBot.create(:info_request, prominence: request_prominence)
  end

  let(:message) do
    FactoryBot.create(
      :incoming_message,
      info_request: info_request,
      prominence: message_prominence
    )
  end

  let(:attachment) do
    FactoryBot.create(
      :body_text,
      body: 'hereisthemaskedtext',
      incoming_message: message,
      prominence: attachment_prominence
    )
  end

  def expect_hidden(hidden_template)
    expect(response.media_type).to eq('text/html')
    expect(response).to render_template(hidden_template)
    expect(response.code).to eq('403')
  end

  describe 'GET show' do
    def show(params = {})
      default_params = {
        incoming_message_id: message.id,
        part: attachment.url_part_number,
        file_name: attachment.display_filename
      }
      default_params[:id] = info_request.id unless params[:public_token]
      rebuild_raw_emails(info_request)
      get :show, params: default_params.merge(params)
    end

    # This is a regression test for a bug where URLs of this form were causing
    # 500 errors instead of 404s.
    #
    # (Note that in fact only the integer-prefix of the URL part is used, so
    # there are *some* “ugly URLs containing a request id that isn\'t an
    # integer” that actually return a 200 response. The point is that IDs of
    # this sort were triggering an error in the error-handling path, causing
    # the wrong sort of error response to be returned in the case where the
    # integer prefix referred to the wrong request.)
    #
    # https://github.com/mysociety/alaveteli/issues/351
    it 'should return 404 for ugly URLs containing a request id that isn\'t an integer' do
      ugly_id = '55195'
      expect { show(id: ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should return 404 when incoming message and request ids don\'t match' do
      expect { show(id: info_request.id + 1) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should return 404 for ugly URLs contain a request id that isn\'t an integer, even if the integer prefix refers to an actual request' do
      ugly_id = '#{FactoryBot.create(:info_request).id}95'
      expect { show(id: ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should redirect to the incoming message if there\'s a wrong part number and an ambiguous filename' do
      show(
        part: attachment.url_part_number + 1,
        file_name: 'invalid-#{attachment.display_filename}'
      )
      expect(response.status).to eq(303)
      expect(response).to redirect_to(incoming_message_path(message))
    end

    it 'should find a uniquely named filename even if the URL part number was wrong' do
      show(part: 5)
      expect(response.body).to match('hereisthemaskedtext')
    end

    it 'should not download attachments with wrong file name' do
      show(file_name: 'http://trying.to.hack')
      expect(response.status).to eq(303)
    end

    context 'when attachment has not been masked' do
      let(:attachment) do
        FactoryBot.create(
          :body_text, :unmasked,
          incoming_message: message,
          prominence: attachment_prominence
        )
      end

      context 'when masked attachment is avaliable before timing out' do
        before do
          allow(IncomingMessage).to receive(
            :get_attachment_by_url_part_number_and_filename!
          ).and_return(attachment)
          allow(attachment).to receive(:masked?).and_return(false, true)
        end

        it 'queues FoiAttachmentMaskJob' do
          expect(FoiAttachmentMaskJob).to receive(:perform_later).
            with(attachment)
          show
        end

        it 'redirects to show action' do
          show
          expect(response).to redirect_to(request.fullpath)
        end
      end

      context 'when response times out waiting for masked attachment' do
        before do
          allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        end

        it 'queues FoiAttachmentMaskJob' do
          expect(FoiAttachmentMaskJob).to receive(:perform_later).
            with(attachment)
          show
        end

        it 'redirects to wait for attachment mask route' do
          allow_any_instance_of(FoiAttachment).to receive(:to_signed_global_id).
            and_return('ABC')
          show
          expect(response).to redirect_to(
            wait_for_attachment_mask_path('ABC', referer: request.fullpath)
          )
        end
      end
    end

    context 'when request is embargoed' do
      let(:info_request) { FactoryBot.create(:embargoed_request) }

      it 'returns an ActiveRecord::RecordNotFound error for an embargoed request' do
        expect { show }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when request is embargoed but shared with public token' do
      let(:info_request) do
        FactoryBot.create(:info_request, :embargoed, public_token: 'ABC')
      end

      it 'should be able to find the request using public token' do
        expect(InfoRequest).to receive(:find_by!).with(public_token: 'ABC').
          and_return(info_request)

        show(public_token: 'ABC', id: nil)

        expect(assigns(:info_request)).to eq(info_request)
      end

      it 'adds noindex header when using public token' do
        expect(InfoRequest).to receive(:find_by!).with(public_token: 'ABC').
          and_return(info_request)

        show(public_token: 'ABC', id: nil)

        expect(response.headers['X-Robots-Tag']).to eq 'noindex'
      end

      it 'passes public token to current ability' do
        expect(Ability).to receive(:new).with(
          nil, project: nil, public_token: true
        ).and_call_original
        show(public_token: 'ABC', id: nil)
      end
    end

    context 'with project_id params and logged in project member' do
      let(:user) { project.owner }
      let(:project) { FactoryBot.create(:project) }

      before do
        sign_in user
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'assigns project' do
        show(project_id: project.id)
        expect(assigns(:project)).to eq project
      end

      it 'passes project to current ability' do
        expect(Ability).to receive(:new).with(
          user, project: project, public_token: false
        ).and_call_original
        show(project_id: project.id)
      end
    end

    context 'with project_id params and logged in non project member' do
      let(:user) { FactoryBot.create(:user) }
      let(:project) { FactoryBot.create(:project) }

      before do
        sign_in user
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'does not assigns project' do
        show(project_id: project.id)
        expect(assigns(:project)).to eq nil
      end

      it 'does not pass project to current ability' do
        expect(Ability).to receive(:new).with(
          user, project: nil, public_token: false
        ).and_call_original
        show(project_id: project.id)
      end
    end

    context 'when the request is hidden' do
      let(:request_prominence) { 'hidden' }

      it 'does not download attachments' do
        show
        expect_hidden('request/hidden')
      end
    end

    context 'when the request is requester_only' do
      let(:request_prominence) { 'requester_only' }

      it 'does not cache an attachment when showing an attachment to the requester' do
        sign_in info_request.user
        expect(@controller).not_to receive(:foi_fragment_cache_write)
        show
      end

      it 'does not cache an attachment when showing an attachment to the admin' do
        sign_in FactoryBot.create(:admin_user)
        expect(@controller).not_to receive(:foi_fragment_cache_write)
        show
      end
    end

    context 'when the request is backpage' do
      let(:request_prominence) { 'backpage' }

      it 'sets a noindex header when viewing' do
        show
        expect(response.headers['X-Robots-Tag']).to eq 'noindex'
      end

      it 'sets a noindex header when viewing a cached copy' do
        show
        expect(response.headers['X-Robots-Tag']).to eq 'noindex'
      end

      context 'when logged in as requester' do
        before { sign_in info_request.user }

        it 'attachment is viewable' do
          show
          expect(response.body).to include('hereisthemaskedtext')
        end

        it 'does not cache an attachment' do
          expect(@controller).not_to receive(:foi_fragment_cache_write)
          show
        end
      end
    end

    context 'when the incoming message has prominence hidden' do
      let(:message_prominence) { 'hidden' }

      it 'does not download attachments for a non-logged in user' do
        show
        expect_hidden('request/hidden_correspondence')
      end

      it 'does not download attachments for the request owner' do
        sign_in info_request.user
        show
        expect_hidden('request/hidden_correspondence')
      end

      it 'downloads attachments for an admin user' do
        sign_in FactoryBot.create(:admin_user)
        show
        expect(response.media_type).to eq('text/plain')
        expect(response).to be_successful
      end

      it 'does not cache an attachment when showing an attachment to the requester' do
        sign_in info_request.user
        expect(@controller).not_to receive(:foi_fragment_cache_write)
        show
      end

      it 'does not cache an attachment when showing an attachment to the admin' do
        sign_in FactoryBot.create(:admin_user)
        expect(@controller).not_to receive(:foi_fragment_cache_write)
        show
      end
    end

    context 'when the incoming message has prominence requester_only' do
      let(:message_prominence) { 'requester_only' }

      it 'does not download attachments for a non-logged in user' do
        show
        expect_hidden('request/hidden_correspondence')
      end

      it 'downloads attachments for the request owner' do
        sign_in info_request.user
        show
        expect(response.media_type).to eq('text/plain')
        expect(response).to be_successful
      end

      it 'downloads attachments for an admin user' do
        sign_in FactoryBot.create(:admin_user)
        show
        expect(response.media_type).to eq('text/plain')
        expect(response).to be_successful
      end
    end

    context 'when the attachment has prominence hidden' do
      let(:attachment_prominence) { 'hidden' }

      it 'does not download attachments for a non-logged in user' do
        show
        expect_hidden('request/hidden_attachment')
      end

      it 'does not download attachments for the request owner' do
        sign_in info_request.user
        show
        expect_hidden('request/hidden_attachment')
      end

      it 'downloads attachments for an admin user' do
        sign_in FactoryBot.create(:admin_user)
        show
        expect(response.media_type).to eq('text/plain')
        expect(response).to be_successful
      end

      it 'does not cache an attachment when showing an attachment to the requester' do
        sign_in info_request.user
        expect(@controller).not_to receive(:foi_fragment_cache_write)
        show
      end

      it 'does not cache an attachment when showing an attachment to the admin' do
        sign_in FactoryBot.create(:admin_user)
        expect(@controller).not_to receive(:foi_fragment_cache_write)
        show
      end
    end

    context 'when the attachment has prominence requester_only' do
      let(:attachment_prominence) { 'requester_only' }

      it 'does not download attachments for a non-logged in user' do
        show
        expect_hidden('request/hidden_attachment')
      end

      it 'downloads attachments for the request owner' do
        sign_in info_request.user
        show
        expect(response.media_type).to eq('text/plain')
        expect(response).to be_successful
      end

      it 'downloads attachments for an admin user' do
        sign_in FactoryBot.create(:admin_user)
        show
        expect(response.media_type).to eq('text/plain')
        expect(response).to be_successful
      end
    end
  end

  describe 'GET show_as_html' do
    def show_as_html(params = {})
      default_params = {
        incoming_message_id: message.id,
        part: attachment.url_part_number,
        file_name: attachment.display_filename
      }
      default_params[:id] = info_request.id unless params[:public_token]
      get :show_as_html, params: default_params.merge(params)
    end

    it 'should be able to find the request using public token' do
      expect(InfoRequest).to receive(:find_by!).with(public_token: '123').
        and_return(info_request)

      show_as_html(public_token: '123', id: nil)

      expect(assigns(:info_request)).to eq(info_request)
    end

    it 'adds noindex header when using public token' do
      expect(InfoRequest).to receive(:find_by!).with(public_token: '123').
        and_return(info_request)

      show_as_html(public_token: '123', id: nil)

      expect(response.headers['X-Robots-Tag']).to eq 'noindex'
    end

    it 'should return 404 for ugly URLs containing a request id that isn\'t an integer' do
      ugly_id = '55195'
      expect { show_as_html(id: ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should return 404 for ugly URLs contain a request id that isn\'t an integer, even if the integer prefix refers to an actual request' do
      ugly_id = FactoryBot.create(:info_request).id.to_s + '95'
      expect { show_as_html(id: ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when request is embargoed' do
      let(:info_request) { FactoryBot.create(:embargoed_request) }

      it 'returns an ActiveRecord::RecordNotFound error' do
        expect { show_as_html }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when attachment has a long filename' do
      let(:long_name) { 'blah' * 150 + '.pdf' }

      let(:attachment) do
        FactoryBot.create(
          :pdf_attachment, filename: long_name, incoming_message: message
        )
      end

      it 'should be successful' do
        show_as_html(file_name: long_name)
        expect(response).to be_successful
      end
    end

    context 'when the request is hidden' do
      let(:request_prominence) { 'hidden' }

      it 'does not generate an HTML version of an attachment for a request whose prominence is hidden even for an admin but should return a 404' do
        sign_in FactoryBot.create(:admin_user)
        expect { show_as_html }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the request is requester_only' do
      let(:request_prominence) { 'requester_only' }
    end

    context 'when the request is backpage' do
      let(:request_prominence) { 'backpage' }

      it 'sets a noindex header when viewing a HTML version' do
        show_as_html
        expect(response.headers['X-Robots-Tag']).to eq 'noindex'
      end

      it 'sets a noindex header when viewing a cached HTML version' do
        show_as_html
        expect(response.headers['X-Robots-Tag']).to eq 'noindex'
      end
    end

    context 'when the incoming message has prominence hidden' do
      let(:message_prominence) { 'hidden' }

      it 'should not generate an HTML version of an attachment for a request whose prominence is hidden even for an admin but should return a 404' do
        sign_in FactoryBot.create(:admin_user)
        expect { show_as_html }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the incoming message has prominence requester_only' do
      let(:message_prominence) { 'requester_only' }

      it 'should not generate an HTML version of an attachment for a request whose prominence is hidden even for an admin but should return a 404' do
        sign_in FactoryBot.create(:admin_user)
        expect { show_as_html }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the attachment has prominence hidden' do
      let(:attachment_prominence) { 'hidden' }

      it 'should not generate an HTML version of an attachment whose prominence is hidden even for an admin but should return a 404' do
        sign_in FactoryBot.create(:admin_user)
        expect { show_as_html }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the attachment has prominence requester_only' do
      let(:attachment_prominence) { 'requester_only' }

      it 'should not generate an HTML version of an attachment whose prominence is hidden even for an admin but should return a 404' do
        sign_in FactoryBot.create(:admin_user)
        expect { show_as_html }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

require 'spec_helper'
require 'cancan/matchers'

RSpec.describe AlaveteliPro::BatchDownloadsController, type: :controller do
  describe 'GET #show' do
    def show(id: '1', format: 'abc')
      get :show, params: { info_request_batch_id: id, format: format }
    end

    context 'without a signed-in user' do
      it 'redirects to the login form' do
        show
        expect(response).
          to redirect_to(signin_path(token: PostRedirect.last.token))
      end
    end

    context 'with a signed-in non-pro user' do
      let(:user) { FactoryBot.create(:user) }
      before { session[:user_id] = user.id }

      it 'redirects to site root' do
        show
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with a signed-in pro user' do
      let(:pro_user) { FactoryBot.create(:pro_user) }
      let(:ability) { Ability.new(pro_user) }

      before do
        session[:user_id] = pro_user.id
        allow(controller).to receive(:current_user).and_return(pro_user)
      end

      context 'when info_request_batch does not exist' do
        it { is_expected.to_not be_able_to(:download, nil) }

        it 'raise 404' do
          expect { show }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when info_request_batch owned by someone else' do
        let(:other_user) { FactoryBot.create(:user) }
        let(:batch) { FactoryBot.create(:info_request_batch, user: other_user) }

        it { is_expected.to_not be_able_to(:download, batch) }

        it 'raise 404' do
          expect { show(id: batch.id) }.to raise_error(
            ActiveRecord::RecordNotFound
          )
        end
      end

      context 'when authorised to download' do
        let(:batch) { FactoryBot.create(:info_request_batch, user: pro_user) }

        before do
          # stub database calls
          allow(pro_user).to(
            receive_message_chain(:info_request_batches, :find).
              and_return(batch)
          )
        end

        it { is_expected.to be_able_to(:download, batch) }

        context 'when HTML format' do
          it 'is a bad request' do
            show(format: 'html')
            expect(response).to have_http_status(:bad_request)
          end
        end

        context 'when ZIP format' do
          before do
            # stub service calls - testing stream content is hard :(
            allow(InfoRequestBatchZip).to receive(:new).
              with(batch, ability: controller.current_ability).
              and_return(double(:zip, name: 'NAME', stream: []))

            show(format: 'zip')
          end

          it 'is a successful request' do
            expect(response).to be_successful
          end

          it 'returns content disposition' do
            expect(response.header['Content-Disposition']).to(
              eq 'attachment; filename="NAME"'
            )
          end

          it 'returns CSV content type' do
            expect(response.header['Content-Type']).to include 'application/zip'
          end

          it 'sets other headers' do
            expect(response.header['Last-Modified']).to_not be_nil
            expect(response.header['X-Accel-Buffering']).to eq 'no'
          end
        end

        context 'when CSV format' do
          before do
            # stub service calls
            allow(InfoRequestBatchMetrics).to receive(:new).with(batch).
              and_return(double(:metrics, to_csv: 'CSV_DATA', name: 'NAME'))

            show(format: 'csv')
          end

          it 'is a successful request' do
            expect(response).to be_successful
          end

          it 'returns CSV data' do
            expect(response.body).to eq 'CSV_DATA'
          end

          it 'returns content disposition' do
            expect(response.header['Content-Disposition']).to(
              eq 'attachment; filename="NAME"'
            )
          end

          it 'returns CSV content type' do
            expect(response.header['Content-Type']).to include 'text/csv'
          end
        end
      end
    end
  end
end

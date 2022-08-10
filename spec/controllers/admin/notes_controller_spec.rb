require 'spec_helper'

RSpec.describe Admin::NotesController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET new' do
    before { get :new }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns the note' do
      expect(assigns[:note]).to be_a(Note)
    end

    it 'renders the correct template' do
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    before do
      post :create, params: params
    end

    shared_context 'successful create' do
      it 'assigns the note' do
        expect(assigns[:note]).to be_a(Note)
      end

      it 'creates the note' do
        expect(assigns[:note].body).to eq('New body')
      end

      it 'sets a notice' do
        expect(flash[:notice]).to eq('Note successfully created.')
      end
    end

    context 'on a successful create of concrete note' do
      include_context 'successful create'

      let!(:note) { FactoryBot.create(:note, :for_public_body) }
      let(:public_body) { note.notable }

      let(:params) do
        {
          id: note.id,
          note: {
            body: 'New body',
            notable_id: public_body.id,
            notable_type: public_body.class.name
          }
        }
      end

      it 'redirects to the public body admin' do
        expect(response).to redirect_to(admin_public_body_path(public_body))
      end
    end

    context 'on an unsuccessful create' do
      let(:params) do
        { note: { body: '' } }
      end

      it 'assigns the note' do
        expect(assigns[:note]).to be_a(Note)
      end

      it 'does not create the note' do
        expect(assigns[:note]).to be_new_record
      end

      it 'renders the form again' do
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET edit' do
    let!(:note) { FactoryBot.create(:note) }

    before { get :edit, params: { id: note.id } }

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'assigns the note' do
      expect(assigns[:note]).to eq(note)
    end

    it 'renders the correct template' do
      expect(response).to render_template(:edit)
    end
  end

  describe 'PATCH #update' do
    let!(:note) { FactoryBot.create(:note) }

    before do
      patch :update, params: params
    end

    shared_context 'successful update' do
      it 'assigns the note' do
        expect(assigns[:note]).to eq(note)
      end

      it 'updates the note' do
        expect(note.reload.body).to eq('New body')
      end

      it 'sets a notice' do
        expect(flash[:notice]).to eq('Note successfully updated.')
      end
    end

    context 'on a successful update of concrete note' do
      include_context 'successful update'

      let!(:note) { FactoryBot.create(:note, :for_public_body) }
      let(:public_body) { note.notable }

      let(:params) do
        {
          id: note.id,
          note: {
            body: 'New body',
            notable_id: public_body.id,
            notable_type: public_body.class.name
          }
        }
      end

      it 'redirects to the public body admin' do
        expect(response).to redirect_to(admin_public_body_path(public_body))
      end
    end

    context 'on an unsuccessful update' do
      let(:params) do
        { id: note.id, note: { body: '' } }
      end

      it 'assigns the note' do
        expect(assigns[:note]).to eq(note)
      end

      it 'does not update the note' do
        expect(note.reload.body).not_to be_blank
      end

      it 'renders the form again' do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:note) { FactoryBot.create(:note) }

    it 'destroys the note' do
      allow(Note).to receive(:find).and_return(note)
      expect(note).to receive(:destroy)
      delete :destroy, params: { id: note.id }
    end

    it 'sets a notice' do
      delete :destroy, params: { id: note.id }
      expect(flash[:notice]).to eq('Note successfully destroyed.')
    end

    context 'when concrete note' do
      let!(:note) { FactoryBot.create(:note, :for_public_body) }
      let(:public_body) { note.notable }

      it 'redirects to the public body admin' do
        delete :destroy, params: { id: note.id }
        expect(response).to redirect_to(admin_public_body_path(public_body))
      end
    end
  end
end

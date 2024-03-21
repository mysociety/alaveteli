require 'spec_helper'

RSpec.describe Admin::CategoriesController do
  describe 'GET index' do
    it 'responds successfully' do
      get :index
      expect(response).to be_successful
    end

    it 'raise 404 for unknown types' do
      expect { get :index, params: { model_type: 'unknown' } }.to(
        raise_error ApplicationController::RouteNotFound
      )
    end

    it 'assigns root for correct model' do
      get :index, params: { model_type: 'PublicBody' }
      expect(assigns(:root)).to eq(PublicBody.category_root)

      get :index, params: { model_type: 'InfoRequest' }
      expect(assigns(:root)).to eq(InfoRequest.category_root)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end
  end

  describe 'GET new' do
    it 'assigns root for correct model' do
      get :new, params: { model_type: 'PublicBody' }
      expect(assigns(:root)).to eq(PublicBody.category_root)

      get :new, params: { model_type: 'InfoRequest' }
      expect(assigns(:root)).to eq(InfoRequest.category_root)
    end

    it 'responds successfully' do
      get :new
      expect(response).to be_successful
    end

    it 'builds a new Category' do
      get :new
      expect(assigns(:category)).to be_new_record
    end

    it 'builds new translations for all locales' do
      get :new
      locales = assigns(:category).translations.map(&:locale)
      expect(locales.map(&:to_s)).to eq(AlaveteliLocalization.available_locales)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template('new')
    end
  end

  describe 'POST create' do
    it 'assigns root for correct model' do
      post :create, params: {
        model_type: 'PublicBody',
        category: { title: 'Title' }
      }
      expect(assigns(:root)).to eq(PublicBody.category_root)

      post :create, params: {
        model_type: 'InfoRequest',
        category: { title: 'Title' }
      }
      expect(assigns(:root)).to eq(InfoRequest.category_root)
    end

    it "default category's parent associations to root" do
      post :create, params: { category: { title: 'Title' } }
      expect(assigns(:category).parents).
        to match_array(PublicBody.category_root)
    end

    it "saves new category's parent associations" do
      parent = FactoryBot.create(:category)
      post :create, params: { category: { parent_ids: [parent.id] } }
      expect(assigns(:category).parents).to match_array(parent)
    end

    context 'on success' do
      let(:params) do
        {
          category_tag: 'new_test_category',
          translations_attributes: {
            'en' => { locale: 'en', title: 'New Category' }
          }
        }
      end

      it 'creates a new category in the default locale' do
        expect {
          post :create, params: { category: params }
        }.to change { Category.count }.by(1)
      end

      it 'can create a category when the default locale is an underscore locale' do
        AlaveteliLocalization.set_locales('es en_GB', 'en_GB')
        post :create, params: { category: { title: 'Category en_GB' } }
        expect(assigns(:category).translations.first.locale).to eq(:en_GB)
      end

      it 'notifies the admin that the category was created' do
        post :create, params: { category: params }
        expect(flash[:notice]).to eq('Category was successfully created.')
      end

      it 'redirects to the categories index' do
        post :create, params: { category: params }
        expect(response).
          to redirect_to(admin_categories_path(model_type: 'PublicBody'))
      end
    end

    context 'on success for multiple locales' do
      let(:params) do
        {
          category_tag: 'new_test_category',
          translations_attributes: {
            'en' => { locale: 'en', title: 'New Category' },
            'es' => { locale: 'es', title: 'Mi Nuevo Category' }
          }
        }
      end

      it 'saves the category' do
        expect {
          post :create, params: { category: params }
        }.to change { Category.count }.by(1)
      end

      it 'saves the default locale translation' do
        post :create, params: { category: params }
        expect(assigns(:category).title(:en)).to eq('New Category')
      end

      it 'saves the alternative locale translation' do
        post :create, params: { category: params }
        expect(assigns(:category).title(:es)).to eq('Mi Nuevo Category')
      end
    end

    context 'on failure' do
      before do
        allow_any_instance_of(Category).to receive(:save).and_return(false)
      end

      it 'renders the form if creating the record was unsuccessful' do
        post :create, params: { category: { title: 'Title' } }
        expect(response).to render_template('new')
      end

      it 'is rebuilt with the given params' do
        post :create, params: { category: { title: 'Title' } }
        expect(assigns(:category).title).to eq('Title')
      end
    end

    context 'on failure for multiple locales' do
      before do
        allow_any_instance_of(Category).to receive(:save).and_return(false)
      end

      let(:params) do
        {
          category_tag: 'new_test_category',
          translations_attributes: {
            'en' => { locale: 'en', title: 'My New Category' },
            'es' => { locale: 'es', title: 'Mi Nuevo Category' }
          }
        }
      end

      it 'is rebuilt with the default locale translation' do
        post :create, params: { category: params }
        expect(assigns(:category).title).to eq('My New Category')
      end

      it 'is rebuilt with the alternative locale translation' do
        post :create, params: { category: params }
        expect(assigns(:category).title(:es)).to eq('Mi Nuevo Category')
      end
    end
  end

  describe 'GET edit' do
    let(:category) do
      FactoryBot.create(
        :category, title_translations: { 'es' => 'Los category' }
      )
    end

    it 'assigns root for correct model' do
      get :edit, params: { model_type: 'PublicBody', id: category.id }
      expect(assigns(:root)).to eq(PublicBody.category_root)

      get :edit, params: { model_type: 'InfoRequest', id: category.id }
      expect(assigns(:root)).to eq(InfoRequest.category_root)
    end

    it 'responds successfully' do
      get :edit, params: { id: category.id }
      expect(response).to be_successful
    end

    it 'finds the requested category' do
      get :edit, params: { id: category.id }
      expect(assigns[:category]).to eq(category)
    end

    it 'builds new translations if the body does not already have a translation in the specified locale' do
      get :edit, params: { id: category.id }
      expect(assigns[:category].translations.map(&:locale)).to include(:fr)
    end

    it 'renders the edit template' do
      get :edit, params: { id: category.id }
      expect(response).to render_template('edit')
    end
  end

  describe 'PUT update' do
    let(:parent) { FactoryBot.create(:category) }

    let(:category) do
      FactoryBot.create(
        :category,
        parents: [parent],
        title_translations: { 'es' => 'Los category' }
      )
    end

    let(:params) do
      {
        category_tag: category.category_tag,
        translations_attributes: {
          'en' => {
            id: category.translation_for(:en).id,
            locale: 'en',
            title: category.title(:en)
          },
          'es' => {
            id: category.translation_for(:es).id,
            locale: 'es',
            title: category.title(:es)
          }
        }
      }
    end

    it 'overrides model type param in favor of the categories root' do
      patch :update, params: {
        model_type: 'PublicBody',
        id: category.id,
        category: params
      }
      expect(assigns(:root)).to eq(PublicBody.category_root)

      patch :update, params: {
        model_type: 'InfoRequest',
        id: category.id,
        category: params
      }
      expect(assigns(:root)).to eq(PublicBody.category_root)
    end

    it 'finds the category to update' do
      patch :update, params: { id: category.id, category: params }
      expect(assigns(:category)).to eq(category)
    end

    it "default category's parent associations to root" do
      patch :update, params: { id: category.id, category: params }
      expect(assigns(:category).parents).
        to match_array(PublicBody.category_root)
    end

    it "saves edits to a category's parent associations" do
      new_parent = FactoryBot.create(:category)
      patch :update, params: {
        id: category.id,
        category: { parent_ids: [new_parent.id] }
      }
      expect(assigns(:category).parents).to match_array(new_parent)
    end

    context 'when the category has associated bodies' do
      before do
        FactoryBot.create(:public_body, tag_string: category.category_tag)
      end

      it 'does not save edits to category' do
        patch :update, params: {
          id: category.id,
          category: { category_tag: 'renamed' }
        }
        expect(assigns(:category).valid?).to eq(false)
      end

      it 'renders the edit action' do
        patch :update, params: {
          id: category.id,
          category: { category_tag: 'renamed' }
        }
        expect(response).to render_template('edit')
      end
    end

    context 'on success' do
      let(:params) do
        {
          translations_attributes: {
            'en' => {
              id: category.translation_for(:en).id,
              locale: 'en',
              title: 'Renamed'
            }
          }
        }
      end

      it 'saves edits to a category' do
        patch :update, params: { id: category.id, category: params }
        expect(assigns(:category).title).to eq('Renamed')
      end

      it 'notifies the admin that the category was created' do
        patch :update, params: { id: category.id, category: params }
        expect(flash[:notice]).to eq('Category was successfully updated.')
      end

      it 'redirects to the category edit page' do
        patch :update, params: { id: category.id, category: params }
        expect(response).
          to redirect_to(admin_categories_path(model_type: 'PublicBody'))
      end

      it 'saves edits to category_tag if the category has no associated bodies' do
        category = FactoryBot.create(:category, category_tag: 'empty')

        patch :update, params: {
          id: category.id,
          category: { category_tag: 'Renamed' }
        }

        expect(assigns(:category).category_tag).to eq('Renamed')
      end

      it "creates a new translation if there isn't one for the default_locale" do
        AlaveteliLocalization.set_locales('es en_GB', 'en_GB')

        patch :update, params: {
          id: category.id,
          category: { title: 'Category en_GB' }
        }

        expect(assigns(:category).translations.map(&:locale)).to include(:en_GB)
      end
    end

    context 'on success for multiple locales' do
      let(:params) do
        {
          category_tag: category.category_tag,
          translations_attributes: {
            'en' => {
              id: category.translation_for(:en).id,
              locale: 'en',
              title: category.title(:en)
            },
            'es' => {
              id: category.translation_for(:es).id,
              locale: 'es',
              title: 'Renamed'
            }
          }
        }
      end

      it 'saves edits to a category in another locale' do
        patch :update, params: { id: category.id, category: params }
        expect(assigns(:category).title(:es)).to eq('Renamed')
        expect(assigns(:category).title(:en)).to eq(category.title(:en))
      end

      it 'adds a new translation' do
        put :update, params: {
          id: category.id,
          category: {
            translations_attributes: {
              'fr' => { locale: 'fr', title: 'Category FR' }
            }
          }
        }

        expect(request.flash[:notice]).to include('successful')
        expect(assigns(:category).title(:fr)).to eq('Category FR')
      end

      it 'adds multiple new translations' do
        patch :update, params: {
          id: category.id,
          category: {
            translations_attributes: {
              'fr' => { locale: 'fr', title: 'Category FR' },
              'cy' => { locale: 'cy', title: 'Category CY' }
            }
          }
        }

        expect(request.flash[:notice]).to include('successful')
        expect(assigns(:category).title(:fr)).to eq('Category FR')
        expect(assigns(:category).title(:cy)).to eq('Category CY')
      end

      it 'updates an existing translation and adds a translation' do
        patch :update, params: {
          id: category.id,
          category: {
            translations_attributes: {
              'es' => {
                id: category.translation_for(:es).id,
                locale: 'es',
                title: 'Category ES'
              },
              'fr' => { locale: 'fr', title: 'Category FR' }
            }
          }
        }

        expect(request.flash[:notice]).to include('successful')
        expect(assigns(:category).title(:es)).to eq('Category ES')
        expect(assigns(:category).title(:fr)).to eq('Category FR')
      end

      it 'redirects to the edit page after a successful update' do
        patch :update, params: { id: category.id, category: { title: 'Title' } }
        expect(response).
          to redirect_to(admin_categories_path(model_type: 'PublicBody'))
      end
    end

    context 'on failure' do
      before do
        allow_any_instance_of(Category).to receive(:save).and_return(false)
      end

      it 'renders the form if creating the record was unsuccessful' do
        patch :update, params: { id: category.id, category: { title: 'Title' } }
        expect(response).to render_template('edit')
      end

      it 'is rebuilt with the given params' do
        patch :update, params: { id: category.id, category: { title: 'Title' } }
        expect(assigns(:category).title).to eq('Title')
      end
    end

    context 'on failure for multiple locales' do
      before do
        allow_any_instance_of(Category).to receive(:save).and_return(false)
      end

      let(:params) do
        {
          category_tag: category.category_tag,
          translations_attributes: {
            'en' => {
              id: category.translation_for(:en).id,
              locale: 'en',
              title: 'My Updated Category'
            },
            'es' => {
              id: category.translation_for(:es).id,
              locale: 'es',
              title: 'Mi Categoria Actualizada'
            }
          }
        }
      end

      it 'is rebuilt with the default locale translation' do
        patch :update, params: { id: category.id, category: params }
        expect(assigns(:category).title(:en)).to eq('My Updated Category')
      end

      it 'is rebuilt with the alternative locale translation' do
        patch :update, params: { id: category.id, category: params }
        expect(assigns(:category).title(:es)).to eq('Mi Categoria Actualizada')
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:category) { FactoryBot.create(:category, category_tag: '123') }

    it 'destroys empty categories' do
      expect {
        delete :destroy, params: { id: category.id }
      }.to change { Category.count }.by(-1)
    end

    it 'destroys non-empty categories' do
      FactoryBot.create(:public_body, tag_string: '123')
      expect {
        delete :destroy, params: { id: category.id }
      }.to change { Category.count }.by(-1)
    end

    it 'notifies the admin that the category was destroyed' do
      delete :destroy, params: { id: category.id }
      expect(flash[:notice]).to eq('Category was successfully destroyed.')
    end

    it 'redirects to the categories index' do
      delete :destroy, params: { id: category.id }
      expect(response).
        to redirect_to(admin_categories_path(model_type: 'PublicBody'))
    end
  end

  describe 'POST reorder' do
    let(:parent) { FactoryBot.create(:category) }
    let!(:category_1) { FactoryBot.create(:category, parents: [parent]) }
    let!(:category_2) { FactoryBot.create(:category, parents: [parent]) }

    it 'responds successfully' do
      patch :reorder, params: {
        id: parent.id, categories: [category_2.id, category_1.id]
      }
      expect(response).to be_successful
    end

    it 'reorders existing child categories' do
      expect {
        patch :reorder, params: {
          id: parent.id, categories: [category_2.id, category_1.id]
        }
      }.to(
        change { parent.children.ids }.
        from([category_1.id, category_2.id]).
        to([category_2.id, category_1.id])
      )
    end

    it 'returns error if trying to reorder non-child categories' do
      other_category = FactoryBot.create(:category)
      patch :reorder, params: {
        id: parent.id, categories: [category_1.id, other_category.id]
      }
      expect(response).to_not be_successful
      expect(response.body).to eq("Couldn't find Category #{other_category.id}")
    end
  end
end

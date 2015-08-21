# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminPublicBodyCategoriesController do

  describe 'GET index' do

    it 'responds successfully' do
      get :index
      expect(response).to be_success
    end

    it 'uses the current locale by default' do
      get :index
      expect(assigns(:locale)).to eq(I18n.locale.to_s)
    end

    it 'sets the locale if the show_locale param is passed' do
      get :index, :show_locale => 'es'
      expect(assigns(:locale)).to eq('es')
    end

    it 'finds all category headings' do
      PublicBodyHeading.destroy_all

      headings = [FactoryGirl.create(:public_body_heading),
                  FactoryGirl.create(:public_body_heading)]

      get :index

      expect(assigns(:category_headings)).to eq(headings)
    end

    it 'finds all categories without their headings' do
      PublicBodyHeading.destroy_all
      PublicBodyCategory.destroy_all

      without_heading = FactoryGirl.create(:public_body_category)

      heading = FactoryGirl.create(:public_body_heading)
      with_heading = FactoryGirl.create(:public_body_category)
      PublicBodyCategoryLink.create!(:public_body_heading_id => heading.id,
                                     :public_body_category_id => with_heading.id)


      get :index
      expect(assigns(:without_heading)).to eq([without_heading])
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end

  end

  describe 'GET new' do

    it 'responds successfully' do
      get :new
      expect(response).to be_success
    end

    it 'builds a new PublicBodyCategory' do
      get :new
      expect(assigns(:public_body_category)).to be_new_record
    end

    it 'builds new translations for all locales' do
      get :new

      translations = assigns(:public_body_category).translations.map{ |t| t.locale.to_s }.sort
      available = I18n.available_locales.map{ |l| l.to_s }.sort

      expect(translations).to eq(available)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template('new')
    end

  end

  describe 'POST create' do

    context 'on success' do

      before(:each) do
        PublicBodyCategory.destroy_all
        @params = { :category_tag => 'new_test_category',
                    :translations_attributes => {
          'en' => { :locale => 'en',
                    :title => 'New Category',
                    :description => 'New category for testing stuff' }
        } }
      end

      it 'creates a new category in the default locale' do
        PublicBodyCategory.destroy_all

        expect {
          post :create, :public_body_category => @params
        }.to change{ PublicBodyCategory.count }.from(0).to(1)
      end

      it "saves the public body category's heading associations" do
        heading = FactoryGirl.create(:public_body_heading)
        params = FactoryGirl.attributes_for(:public_body_category)

        post :create, :public_body_category => @params,
          :headings => { "heading_#{ heading.id }" => heading.id }

        category = PublicBodyCategory.find_by_title(@params[:translations_attributes]['en'][:title])
        expect(category.public_body_headings).to eq([heading])
      end

      it 'notifies the admin that the category was created' do
        post :create, :public_body_category => @params
        expect(flash[:notice]).to eq('Category was successfully created.')
      end

      it 'redirects to the categories index' do
        post :create, :public_body_category => @params
        expect(response).to redirect_to(admin_categories_path)
      end

    end

    context 'on success for multiple locales' do

      before(:each) do
        PublicBodyCategory.destroy_all
        @params = { :category_tag => 'new_test_category',
                    :translations_attributes => {
          'en' => { :locale => 'en',
                    :title => 'New Category',
                    :description => 'New category for testing stuff' },
                    'es' => { :locale => 'es',
                              :title => 'Mi Nuevo Category',
                              :description => 'ES Description' }
        } }
      end

      it 'saves the category' do
        expect {
          post :create, :public_body_category => @params
        }.to change{ PublicBodyCategory.count }.from(0).to(1)
      end

      it 'saves the default locale translation' do
        post :create, :public_body_category => @params

        category = PublicBodyCategory.find_by_title('New Category')

        I18n.with_locale(:en) do
          expect(category.title).to eq('New Category')
        end
      end

      it 'saves the alternative locale translation' do
        post :create, :public_body_category => @params

        category = PublicBodyCategory.find_by_title('New Category')

        I18n.with_locale(:es) do
          expect(category.title).to eq('Mi Nuevo Category')
        end
      end

    end

    context 'on failure' do

      it 'renders the form if creating the record was unsuccessful' do
        post :create, :public_body_category => { :title => '' }
        expect(response).to render_template('new')
      end

      it 'is rebuilt with the given params' do
        post :create, :public_body_category => { :title => 'Need a description' }
        expect(assigns(:public_body_category).title).to eq('Need a description')
      end

    end

    context 'on failure for multiple locales' do

      before(:each) do
        @params = { :category_tag => 'new_test_category',
                    :translations_attributes => {
          'en' => { :locale => 'en',
                    :title => 'Need a description',
                    :description => nil },
                    'es' => { :locale => 'es',
                              :title => 'Mi Nuevo Category',
                              :description => 'ES Description' }
        } }
      end

      it 'is rebuilt with the default locale translation' do
        post :create, :public_body_category => @params
        expect(assigns(:public_body_category).title).to eq('Need a description')
      end

      it 'is rebuilt with the alternative locale translation' do
        post :create, :public_body_category => @params

        I18n.with_locale(:es) do
          expect(assigns(:public_body_category).title).to eq('Mi Nuevo Category')
        end
      end

    end

  end

  describe 'GET edit' do

    before do
      @category = FactoryGirl.create(:public_body_category)
      I18n.with_locale('es') do
        @category.title = 'Los category'
        @category.description = 'ES Description'
        @category.save!
      end
    end

    it 'responds successfully' do
      get :edit, :id => @category.id
      expect(response).to be_success
    end

    it 'finds the requested category' do
      get :edit, :id => @category.id
      expect(assigns[:public_body_category]).to eq(@category)
    end

    it 'builds new translations if the body does not already have a translation in the specified locale' do
      get :edit, :id => @category.id
      expect(assigns[:public_body_category].translations.map(&:locale)).to include(:fr)
    end

    it 'finds the public bodies tagged with the category tag' do
      # FIXME: I wanted to call PublicBody.destroy_all here so that we
      # have a known DB state, but the constraints were preventing the
      # deletion of the fixture data
      FactoryGirl.create(:public_body, :tag_string => 'wont_be_found')

      category = FactoryGirl.create(:public_body_category, :category_tag => 'spec')
      expected_bodies = [FactoryGirl.create(:public_body, :tag_string => 'spec'),
                         FactoryGirl.create(:public_body, :tag_string => 'spec')]

      get :edit, :id => category.id

      expect(assigns(:tagged_public_bodies).sort).to eq(expected_bodies.sort)
    end

    it 'renders the edit template' do
      get :edit, :id => @category.id
      expect(response).to render_template('edit')
    end

  end

  describe 'PUT update' do

    before do
      @heading = FactoryGirl.create(:public_body_heading)
      @category = FactoryGirl.create(:public_body_category)
      link = FactoryGirl.create(:public_body_category_link,
                                :public_body_category => @category,
                                :public_body_heading => @heading,
                                :category_display_order => 0)
      @tag = @category.category_tag
      I18n.with_locale('es') do
        @category.title = 'Los category'
        @category.description = 'ES Description'
        @category.save!
      end

      @params = { :category_tag => @category.category_tag,
                  :translations_attributes => {
        'en' => { :id => @category.translation_for(:en).id,
                  :locale => 'en',
                  :title => @category.title(:en),
                  :description => @category.description(:en) },
        'es' => { :id => @category.translation_for(:es).id,
                  :locale => 'es',
                  :title => @category.title(:es),
                  :description => @category.description(:es) }
      } }
    end

    it 'finds the category to update' do
      post :update, :id => @category.id,
        :public_body_category => @params
      expect(assigns(:public_body_category)).to eq(@category)
    end

    it 'finds the public bodies tagged with the category tag' do
      # FIXME: I wanted to call PublicBody.destroy_all here so that we
      # have a known DB state, but the constraints were preventing the
      # deletion of the fixture data
      FactoryGirl.create(:public_body, :tag_string => 'wont_be_found')

      category = FactoryGirl.create(:public_body_category, :category_tag => 'spec')
      expected_bodies = [FactoryGirl.create(:public_body, :tag_string => 'spec'),
                         FactoryGirl.create(:public_body, :tag_string => 'spec')]

      post :update, :id => category.id,
        :public_body_category => category.serializable_hash.except(:title, :description)

      expect(assigns(:tagged_public_bodies)).to match_array(expected_bodies)
    end

    it "saves edits to a public body category's heading associations" do
      # We already have a heading from the before block. Here we're going
      # to update to a new heading.
      heading = FactoryGirl.create(:public_body_heading)

      post :update, :id => @category.id,
        :public_body_category => {
        :translations_attributes => {
          'en' => { :id => @category.translation_for(:en).id,
                    :title => 'Renamed' }
        }
      },
      :headings => { "heading_#{ heading.id }" => heading.id }

      category = PublicBodyCategory.find(@category.id)
      expect(category.public_body_headings).to eq([heading])
    end

    context 'when the category has associated bodies' do

      it 'does not save edits to category_tag' do
        body = FactoryGirl.create(:public_body, :tag_string => @tag)

        post :update, :id => @category.id,
          :public_body_category => { :category_tag => 'Renamed' }


        category = PublicBodyCategory.find(@category.id)
        expect(category.category_tag).to eq(@tag)
      end

      it 'notifies the user that the category_tag could not be updated' do
        body = FactoryGirl.create(:public_body, :tag_string => @tag)
        msg = %Q(There are authorities associated with this category,
                         so the tag can't be renamed).squish

                         post :update, :id => @category.id,
                           :public_body_category => { :category_tag => 'Renamed' }

                         expect(flash[:error]).to eq(msg)
      end

      it 'renders the edit action' do
        body = FactoryGirl.create(:public_body, :tag_string => @tag)

        post :update, :id => @category.id,
          :public_body_category => { :category_tag => 'Renamed' }

        expect(response).to render_template('edit')
      end

    end

    context 'on success' do

      before(:each) do
        @params = { :id => @category.id,
                    :public_body_category => {
          :translations_attributes => {
            'en' => { :id => @category.translation_for(:en).id,
                      :title => 'Renamed' }
          }
        }
        }
      end

      it 'saves edits to a public body category' do
        post :update, @params
        category = PublicBodyCategory.find(@category.id)
        expect(category.title).to eq('Renamed')
      end

      it 'notifies the admin that the category was created' do
        post :update, @params
        expect(flash[:notice]).to eq('Category was successfully updated.')
      end

      it 'redirects to the category edit page' do
        post :update, @params
        expect(response).to redirect_to(edit_admin_category_path(@category))
      end

      it 'saves edits to category_tag if the category has no associated bodies' do
        category = FactoryGirl.create(:public_body_category, :category_tag => 'empty')

        post :update, :id => category.id,
          :public_body_category => { :category_tag => 'Renamed' }

        category = PublicBodyCategory.find(category.id)
        expect(category.category_tag).to eq('Renamed')
      end

    end

    context 'on success for multiple locales' do

      it "saves edits to a public body category in another locale" do
        expect(@category.title(:es)).to eq('Los category')
        post :update, :id => @category.id,
          :public_body_category => {
          :translations_attributes => {
            'en' => { :id => @category.translation_for(:en).id,
                      :locale => 'en',
                      :title => @category.title(:en),
                      :description => @category.description(:en) },
            'es' => { :id => @category.translation_for(:es).id,
                      :locale => 'es',
                      :title => 'Renamed',
                      :description => 'ES Description' }
          }
        }

          category = PublicBodyCategory.find(@category.id)
          expect(category.title(:es)).to eq('Renamed')
          expect(category.title(:en)).to eq(@category.title(:en))
      end

      it 'adds a new translation' do
        @category.translation_for(:es).destroy
        @category.reload

        put :update, {
          :id => @category.id,
          :public_body_category => {
            :translations_attributes => {
              'en' => { :id => @category.translation_for(:en).id,
                        :locale => 'en',
                        :title => @category.title(:en),
                        :description => @category.description(:en) },
              'es' => { :locale => "es",
                        :title => "Example Public Body Category ES",
                        :description => @category.description(:es) }
            }
          }
        }

        expect(request.flash[:notice]).to include('successful')

        pbc = PublicBodyCategory.find(@category.id)

        I18n.with_locale(:es) do
          expect(pbc.title).to eq('Example Public Body Category ES')
        end
      end

      it 'adds new translations' do
        @category.translation_for(:es).destroy
        @category.reload

        post :update, {
          :id => @category.id,
          :public_body_category => {
            :translations_attributes => {
              'en' => { :id => @category.translation_for(:en).id,
                        :locale => 'en',
                        :title => @category.title(:en),
                        :description => @category.description(:en) },
              'es' => { :locale => "es",
                        :title => "Example Public Body Category ES",
                        :description => 'ES Description' },
                        'fr' => { :locale => "fr",
                                  :title => "Example Public Body Category FR",
                                  :description => 'FR Description' }
            }
          }
        }

        expect(request.flash[:notice]).to include('successful')

        pbc = PublicBodyCategory.find(@category.id)

        I18n.with_locale(:es) do
          expect(pbc.title).to eq('Example Public Body Category ES')
        end
        I18n.with_locale(:fr) do
          expect(pbc.title).to eq('Example Public Body Category FR')
        end
      end

      it 'updates an existing translation and adds a third translation' do
        post :update, {
          :id => @category.id,
          :public_body_category => {
            :translations_attributes => {
              'en' => { :id => @category.translation_for(:en).id,
                        :locale => 'en',
                        :title => @category.title(:en),
                        :description => @category.description(:en) },
              # Update existing translation
              'es' => { :id => @category.translation_for(:es).id,
                        :locale => "es",
                        :title => "Renamed Example Public Body Category ES",
                        :description => @category.description },
                        # Add new translation
                        'fr' => { :locale => "fr",
                                  :title => "Example Public Body Category FR",
                                  :description => @category.description }
            }
          }
        }

        expect(request.flash[:notice]).to include('successful')

        pbc = PublicBodyCategory.find(@category.id)

        I18n.with_locale(:es) do
          expect(pbc.title).to eq('Renamed Example Public Body Category ES')
        end
        I18n.with_locale(:fr) do
          expect(pbc.title).to eq('Example Public Body Category FR')
        end
      end

      it "redirects to the edit page after a successful update" do
        post :update, :id => @category.id,
          :public_body_category => {
          :translations_attributes => {
            'en' => { :id => @category.translation_for(:en).id,
                      :locale => 'en',
                      :title => @category.title(:en),
                      :description => @category.description(:en) }
          } }

          expect(response).to redirect_to(edit_admin_category_path(@category))
      end

    end

    context 'on failure' do

      it 'renders the form if creating the record was unsuccessful' do
        post :update, :id => @category.id,
          :public_body_category => {
          :translations_attributes => {
            'en' => { :id => @category.translation_for(:en).id,
                      :locale => 'en',
                      :title => '',
                      :description => @category.description(:en) }
          } }
          expect(response).to render_template('edit')
      end

      it 'is rebuilt with the given params' do
        post :update, :id => @category.id,
          :public_body_category => {
          :translations_attributes => {
            'en' => { :id => @category.translation_for(:en).id,
                      :locale => 'en',
                      :title => 'Need a description',
                      :description => '' }
          } }
          expect(assigns(:public_body_category).title).to eq('Need a description')
      end

    end

    context 'on failure for multiple locales' do

      before(:each) do
        @params = { :category_tag => 'new_test_category',
                    :translations_attributes => {
          'en' => { :id => @category.translation_for(:en).id,
                    :locale => 'en',
                    :title => 'Need a description',
                    :description => '' },
                    'es' => { :id => @category.translation_for(:es).id,
                              :locale => 'es',
                              :title => 'Mi Nuevo Category',
                              :description => 'ES Description' }
        } }
      end

      it 'is rebuilt with the default locale translation' do
        post :update, :id => @category.id,
          :public_body_category => @params
        expect(assigns(:public_body_category).title(:en)).to eq('Need a description')
      end

      it 'is rebuilt with the alternative locale translation' do
        post :update, :id => @category.id,
          :public_body_category => @params

        I18n.with_locale(:es) do
          expect(assigns(:public_body_category).title).to eq('Mi Nuevo Category')
        end
      end

    end

  end

  describe 'DELETE destroy' do

    it 'destroys empty public body categories' do
      PublicBodyCategory.destroy_all

      category = FactoryGirl.create(:public_body_category)

      expect{
        post :destroy, :id => category.id
      }.to change{ PublicBodyCategory.count }.from(1).to(0)
    end

    it 'destroys non-empty public body categories' do
      PublicBodyCategory.destroy_all

      # FIXME: Couldn't create the PublicBodyCategory with a Factory
      # because #authorities= doesn't exist?
      # undefined method `authorities=' for
      # #<PublicBodyCategory:0x7f55cbb84f70>
      authority = FactoryGirl.create(:public_body)
      category = PublicBodyCategory.create(:title => "In-Use Category",
                                           :category_tag => "empty",
                                           :description => "-",
                                           :authorities => [authority])

      expect{
        post :destroy, :id => category.id
      }.to change{ PublicBodyCategory.count }.from(1).to(0)
    end

    it 'notifies the admin that the category was destroyed' do
      category = FactoryGirl.create(:public_body_category)
      post :destroy, :id => category.id
      expect(flash[:notice]).to eq('Category was successfully destroyed.')
    end

    it 'redirects to the categories index' do
      category = FactoryGirl.create(:public_body_category)
      post :destroy, :id => category.id
      expect(response).to redirect_to(admin_categories_path)
    end

  end
end

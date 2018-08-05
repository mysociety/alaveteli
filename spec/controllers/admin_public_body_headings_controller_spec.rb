# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminPublicBodyHeadingsController do

  describe 'GET new' do

    it 'responds successfully' do
      get :new
      expect(response).to be_success
    end

    it 'builds a new PublicBodyHeading' do
      get :new
      expect(assigns(:public_body_heading)).to be_new_record
    end

    it 'builds new translations for all locales' do
      get :new

      translations = assigns(:public_body_heading).
                       translations.map { |t| t.locale.to_s }.sort

      expect(translations).
        to match_array(AlaveteliLocalization.available_locales)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template('new')
    end

  end

  describe 'POST create' do

    context 'on success' do

      before(:each) do
        PublicBodyHeading.destroy_all
        @params = { :translations_attributes => {
                      'en' => { :locale => 'en',
                                :name => 'New Heading' }
        } }
      end

      it 'creates a new heading in the default locale' do
        expect {
          post :create, params: { :public_body_heading => @params }
        }.to change{ PublicBodyHeading.count }.from(0).to(1)
      end

      it 'can create a heading when the default locale is an underscore locale' do
        AlaveteliLocalization.set_locales('es en_GB', 'en_GB')
        post :create, params: {
                        :public_body_heading => { :name => 'New Heading en_GB' }
                      }

        expect(
          PublicBodyHeading.
            find_by(:name => 'New Heading en_GB').
              translations.
                first.
                  locale
        ).to eq(:en_GB)
      end

      it 'notifies the admin that the heading was created' do
        post :create, params: { :public_body_heading => @params }
        expect(flash[:notice]).to eq('Heading was successfully created.')
      end

      it 'redirects to the categories index' do
        post :create, params: { :public_body_heading => @params }
        expect(response).to redirect_to(admin_categories_path)
      end

    end

    context 'on success for multiple locales' do

      before(:each) do
        PublicBodyHeading.destroy_all
        @params = { :translations_attributes => {
                      'en' => { :locale => 'en',
                                :name => 'New Heading' },
                      'es' => { :locale => 'es',
                                :name => 'Mi Nuevo Heading' }
        } }
      end

      it 'saves the heading' do
        expect {
          post :create, params: { :public_body_heading => @params }
        }.to change{ PublicBodyHeading.count }.from(0).to(1)
      end

      it 'saves the default locale translation' do
        post :create, params: { :public_body_heading => @params }

        heading = PublicBodyHeading.where(:name => 'New Heading').first

        AlaveteliLocalization.with_locale(:en) do
          expect(heading.name).to eq('New Heading')
        end
      end

      it 'saves the alternative locale translation' do
        post :create, params: { :public_body_heading => @params }

        heading = PublicBodyHeading.where(:name => 'New Heading').first

        AlaveteliLocalization.with_locale(:es) do
          expect(heading.name).to eq('Mi Nuevo Heading')
        end
      end

    end

    context 'on failure' do

      it 'renders the form if creating the record was unsuccessful' do
        post :create, params: { :public_body_heading => { :name => '' } }
        expect(response).to render_template('new')
      end

      it 'is rebuilt with the given params' do
        post :create,
             params: {
               :public_body_heading => { :name => 'Need a description' }
             }
        expect(assigns(:public_body_heading).name).to eq('Need a description')
      end

    end

    context 'on failure for multiple locales' do

      before(:each) do
        @params = { :translations_attributes => {
                      'en' => { :locale => 'en',
                                :name => 'Need a description' },
                      'es' => { :locale => 'es',
                                :name => 'Mi Nuevo Heading' }
        } }
      end

      it 'is rebuilt with the default locale translation' do
        post :create, params: { :public_body_heading => @params }
        expect(assigns(:public_body_heading).name).to eq('Need a description')
      end

      it 'is rebuilt with the alternative locale translation' do
        post :create, params: { :public_body_heading => @params }

        AlaveteliLocalization.with_locale(:es) do
          expect(assigns(:public_body_heading).name).to eq('Mi Nuevo Heading')
        end
      end

    end

  end

  describe 'GET edit' do

    before do
      @heading = FactoryBot.create(:public_body_heading)
      AlaveteliLocalization.with_locale('es') do
        @heading.name = 'Los heading'
        @heading.save!
      end
    end

    it 'responds successfully' do
      get :edit, params: { :id => @heading.id }
      expect(response).to be_success
    end

    it 'finds the requested heading' do
      get :edit, params: { :id => @heading.id }
      expect(assigns[:public_body_heading]).to eq(@heading)
    end

    it 'builds new translations if the body does not already have a translation in the specified locale' do
      get :edit, params: { :id => @heading.id }
      expect(assigns[:public_body_heading].translations.map(&:locale)).to include(:fr)
    end

    it 'renders the edit template' do
      get :edit, params: { :id => @heading.id }
      expect(response).to render_template('edit')
    end

  end

  describe 'PUT update' do

    before do
      @heading = FactoryBot.create(:public_body_heading)
      AlaveteliLocalization.with_locale('es') do
        @heading.name = 'Los heading'
        @heading.save!
      end
      @params = { :translations_attributes => {
                    'en' => { :id => @heading.translation_for(:en).id,
                              :locale => 'en',
                              :name => @heading.name(:en) },
                    'es' => { :id => @heading.translation_for(:es).id,
                              :locale => 'es',
                              :title => @heading.name(:es) }
      } }
    end

    it 'finds the heading to update' do
      post :update, params: {
                      :id => @heading.id,
                      :public_body_category => @params
                    }
      expect(assigns(:public_body_heading)).to eq(@heading)
    end

    context 'on success' do

      before(:each) do
        @params = { :id => @heading.id,
                    :public_body_heading => {
                      :translations_attributes => {
                        'en' => { :id => @heading.translation_for(:en).id,
                                  :name => 'Renamed' }
                      }
                    }
                    }
      end

      it 'saves edits to a public body heading' do
        post :update, params: @params
        heading = PublicBodyHeading.find(@heading.id)
        expect(heading.name).to eq('Renamed')
      end

      it 'notifies the admin that the heading was updated' do
        post :update, params: @params
        expect(flash[:notice]).to eq('Heading was successfully updated.')
      end

      it "creates a new translation if there isn't one for the default_locale" do
        AlaveteliLocalization.set_locales('es en_GB', 'en_GB')

        post :update, params: {
                        :id => @heading.id,
                        :public_body_heading => {
                          :name => 'Heading en_GB'
                        }
                      }

        expect(PublicBodyHeading.find(@heading.id).translations.map(&:locale)).
          to include(:en_GB)
      end

      it 'redirects to the heading edit page' do
        post :update, params: @params
        expect(response).to redirect_to(edit_admin_heading_path(@heading))
      end

    end

    context 'on success for multiple locales' do

      it 'saves edits to a public body heading in another locale' do
        expect(@heading.name(:es)).to eq('Los heading')
        post :update, params: {
                        :id => @heading.id,
                        :public_body_heading => {
                          :translations_attributes => {
                            'en' => {
                              :id => @heading.translation_for(:en).id,
                              :locale => 'en',
                              :name => @heading.name(:en)
                            },
                            'es' => {
                              :id => @heading.translation_for(:es).id,
                              :locale => 'es',
                              :name => 'Renamed'
                            }
                          }
                        }
                      }

        heading = PublicBodyHeading.find(@heading.id)
        expect(heading.name(:es)).to eq('Renamed')
        expect(heading.name(:en)).to eq(@heading.name(:en))
      end

      it 'adds a new translation' do
        @heading.translation_for(:es).destroy
        @heading.reload

        put :update, params: {
                       :id => @heading.id,
                       :public_body_heading => {
                         :translations_attributes => {
                           'en' => {
                             :id => @heading.translation_for(:en).id,
                             :locale => 'en',
                             :name => @heading.name(:en)
                           },
                           'es' => {
                             :locale => "es",
                             :name => "Example Public Body Heading ES"
                           }
                         }
                       }
                     }

        expect(request.flash[:notice]).to include('successful')

        heading = PublicBodyHeading.find(@heading.id)

        AlaveteliLocalization.with_locale(:es) do
          expect(heading.name).to eq('Example Public Body Heading ES')
        end
      end

      it 'adds new translations' do
        @heading.translation_for(:es).destroy
        @heading.reload

        post :update, params: {
                        :id => @heading.id,
                        :public_body_heading => {
                          :translations_attributes => {
                            'en' => {
                              :id => @heading.translation_for(:en).id,
                              :locale => 'en',
                              :name => @heading.name(:en)
                            },
                            'es' => {
                              :locale => "es",
                              :name => "Example Public Body Heading ES"
                            },
                            'fr' => {
                              :locale => "fr",
                              :name => "Example Public Body Heading FR"
                            }
                          }
                        }
                      }

        expect(request.flash[:notice]).to include('successful')

        heading = PublicBodyHeading.find(@heading.id)

        AlaveteliLocalization.with_locale(:es) do
          expect(heading.name).to eq('Example Public Body Heading ES')
        end
        AlaveteliLocalization.with_locale(:fr) do
          expect(heading.name).to eq('Example Public Body Heading FR')
        end
      end

      it 'updates an existing translation and adds a third translation' do
        post :update, params: {
          :id => @heading.id,
          :public_body_heading => {
            :translations_attributes => {
              'en' => { :id => @heading.translation_for(:en).id,
                        :locale => 'en',
                        :name => @heading.name(:en) },
              # Update existing translation
              'es' => { :id => @heading.translation_for(:es).id,
                        :locale => "es",
                        :name => "Renamed Example Public Body Heading ES" },
              # Add new translation
              'fr' => { :locale => "fr",
                        :name => "Example Public Body Heading FR" }
            }
          }
        }

        expect(request.flash[:notice]).to include('successful')

        heading = PublicBodyHeading.find(@heading.id)

        AlaveteliLocalization.with_locale(:es) do
          expect(heading.name).to eq('Renamed Example Public Body Heading ES')
        end
        AlaveteliLocalization.with_locale(:fr) do
          expect(heading.name).to eq('Example Public Body Heading FR')
        end
      end

      it "redirects to the edit page after a successful update" do
        post :update, params: {
                        :id => @heading.id,
                        :public_body_heading => {
                          :translations_attributes => {
                            'en' => {
                              :id => @heading.translation_for(:en).id,
                              :locale => 'en',
                              :name => @heading.name(:en)
                            }
                          }
                        }
                      }

        expect(response).to redirect_to(edit_admin_heading_path(@heading))
      end

    end

    context 'on failure' do

      it 'renders the form if creating the record was unsuccessful' do
        post :update, params: {
                        :id => @heading.id,
                        :public_body_heading => {
                          :translations_attributes => {
                            'en' => {
                              :id => @heading.translation_for(:en).id,
                              :locale => 'en',
                              :name => ''
                            }
                          }
                        }
                      }
        expect(response).to render_template('edit')
      end

      it 'is rebuilt with the given params' do
        post :update, params: {
                        :id => @heading.id,
                        :public_body_heading => {
                          :translations_attributes => {
                            'en' => {
                              :id => @heading.translation_for(:en).id,
                              :locale => 'en',
                              :name => 'Need a description'
                            }
                          }
                        }
                      }
        expect(assigns(:public_body_heading).name).to eq('Need a description')
      end

    end

    context 'on failure for multiple locales' do

      before(:each) do
        @params = { :translations_attributes => {
                      'en' => { :id => @heading.translation_for(:en).id,
                                :locale => 'en',
                                :name => '' },
                      'es' => { :id => @heading.translation_for(:es).id,
                                :locale => 'es',
                                :name => 'Mi Nuevo Heading' }
        } }
      end

      it 'is rebuilt with the default locale translation' do
        post :update, params: {
                        :id => @heading.id,
                        :public_body_heading => @params
                      }
        expect(assigns(:public_body_heading).name(:en)).to eq('')
      end

      it 'is rebuilt with the alternative locale translation' do
        post :update, params: {
                        :id => @heading.id,
                        :public_body_heading => @params
                      }

        AlaveteliLocalization.with_locale(:es) do
          expect(assigns(:public_body_heading).name).to eq('Mi Nuevo Heading')
        end
      end

    end

  end

  describe 'DELETE destroy' do

    it 'destroys the public body heading' do
      PublicBodyHeading.destroy_all

      heading = FactoryBot.create(:public_body_heading)

      expect {
        post :destroy, params: { :id => heading.id }
      }.to change{ PublicBodyHeading.count }.from(1).to(0)
    end

    it 'destroys a heading that has associated categories' do
      PublicBodyHeading.destroy_all
      PublicBodyCategory.destroy_all

      heading = FactoryBot.create(:public_body_heading)
      category = FactoryBot.create(:public_body_category)
      link = FactoryBot.create(:public_body_category_link,
                               :public_body_category => category,
                               :public_body_heading => heading,
                               :category_display_order => 0)

      expect {
        post :destroy, params: { :id => heading.id }
      }.to change{ PublicBodyHeading.count }.from(1).to(0)
    end

    it 'notifies the admin that the heading was destroyed' do
      heading = FactoryBot.create(:public_body_heading)
      post :destroy, params: { :id => heading.id }
      expect(flash[:notice]).to eq('Heading was successfully destroyed.')
    end

    it 'redirects to the categories index' do
      heading = FactoryBot.create(:public_body_heading)
      post :destroy, params: { :id => heading.id }
      expect(response).to redirect_to(admin_categories_path)
    end

  end

  context 'when reordering public body headings' do

    render_views

    before do
      @first = FactoryBot.create(:public_body_heading, :display_order => 0)
      @second = FactoryBot.create(:public_body_heading, :display_order => 1)
      @default_params = { :headings => [@second.id, @first.id] }
    end

    def make_request(params=@default_params)
      post :reorder, params: params
    end

    context 'when handling valid input' do

      it 'should reorder headings according to their position in the submitted params' do
        make_request
        expect(PublicBodyHeading.find(@second.id).display_order).to eq(0)
        expect(PublicBodyHeading.find(@first.id).display_order).to eq(1)
      end

      it 'should return a "success" status' do
        make_request
        expect(response).to be_success
      end
    end

    context 'when handling invalid input' do

      before do
        @params = { :headings => [@second.id, @first.id, @second.id + 1]}
      end

      it 'should return an "unprocessable entity" status and an error message' do
        make_request(@params)
        assert_response :unprocessable_entity
        expect(response.body).to match("Couldn't find PublicBodyHeading with 'id'")
      end

      it 'should not reorder headings' do
        make_request(@params)
        expect(PublicBodyHeading.find(@first.id).display_order).to eq(0)
        expect(PublicBodyHeading.find(@second.id).display_order).to eq(1)
      end

    end
  end

  context 'when reordering public body categories' do

    render_views

    before do
      @heading = FactoryBot.create(:public_body_heading)
      @first_category = FactoryBot.create(:public_body_category)
      @first_link = FactoryBot.create(:public_body_category_link,
                                      :public_body_category => @first_category,
                                      :public_body_heading => @heading,
                                      :category_display_order => 0)
      @second_category = FactoryBot.create(:public_body_category)
      @second_link = FactoryBot.create(:public_body_category_link,
                                       :public_body_category => @second_category,
                                       :public_body_heading => @heading,
                                       :category_display_order => 1)
      @default_params = { :categories => [@second_category.id, @first_category.id],
                          :id => @heading }
      @old_order = [@first_category, @second_category]
      @new_order = [@second_category, @first_category]
    end

    def make_request(params=@default_params)
      post :reorder_categories, params: params
    end

    context 'when handling valid input' do

      it 'should reorder categories for the heading according to their position \
                in the submitted params' do

        expect(@heading.public_body_categories).to eq(@old_order)
        make_request
        expect(@heading.public_body_categories.reload).to eq(@new_order)
      end

      it 'should return a success status' do
        make_request
        expect(response).to be_success
      end
    end

    context 'when handling invalid input' do

      before do
        @new_category = FactoryBot.create(:public_body_category)
        @params = @default_params.merge(:categories => [@second_category.id,
                                                        @first_category.id,
                                                        @new_category.id])
      end

      it 'should return an "unprocessable entity" status and an error message' do
        make_request(@params)
        assert_response :unprocessable_entity
        expect(response.body).to match("Couldn't find PublicBodyCategoryLink")
      end

      it 'should not reorder the categories for the heading' do
        make_request(@params)
        expect(@heading.public_body_categories.reload).to eq(@old_order)
      end
    end

  end
end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminPublicBodyController do

  describe 'GET #index' do

    it "returns successfully" do
      get :index
      expect(response).to be_success
    end

    it "searches for 'humpa'" do
      get :index, params: { :query => "humpa" }
      expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
    end

    it "searches for 'humpa' in another locale" do
      get :index, params: { :query => "humpa", :locale => "es" }
      expect(assigns[:public_bodies]).to eq([ public_bodies(:humpadink_public_body) ])
    end

  end

  describe 'GET #show' do
    let(:public_body){ FactoryBot.create(:public_body) }
    let(:info_request){ FactoryBot.create(:info_request,
                                          :public_body => public_body) }
    let(:admin_user){ FactoryBot.create(:admin_user) }
    let(:pro_admin_user){ FactoryBot.create(:pro_admin_user) }

    it "returns successfully" do
      get :show, params: { :id => public_body.id },
                 session: { :user_id => admin_user.id }
      expect(response).to be_success
    end

    it "sets a using_admin flag" do
      get :show, params: { :id => public_body.id},
                 session: { :user_id => admin_user.id }
      expect(session[:using_admin]).to eq(1)
    end

    it "shows a public body in another locale" do
      AlaveteliLocalization.with_locale('es') do
        public_body.name = 'El Public Body'
        public_body.save
      end
      get :show, params: { :id => public_body.id, :locale => "es" },
                 session: { :user_id => admin_user.id }
      expect(assigns[:public_body].name).to eq 'El Public Body'
    end

    it 'does not include embargoed requests if the current user is
        not a pro admin user' do
      info_request.create_embargo
      get :show, params: { :id => public_body.id },
                 session: { :user_id => admin_user.id }
      expect(assigns[:info_requests].include?(info_request)).to be false
    end

    context 'when pro is enabled' do

      it 'does not include embargoed requests if the current user is
          not a pro admin user' do
        with_feature_enabled(:alaveteli_pro) do
          info_request.create_embargo
          get :show, params: { :id => public_body.id },
                     session: { :user_id => admin_user.id }
          expect(assigns[:info_requests].include?(info_request)).to be false
        end
      end


      it 'includes embargoed requests if the current user is a pro admin
          user' do
        with_feature_enabled(:alaveteli_pro) do
          info_request.create_embargo
          get :show, params: { :id => public_body.id },
                     session: { :user_id => pro_admin_user.id }
          expect(assigns[:info_requests].include?(info_request)).to be true
        end
      end
    end

  end

  describe 'GET #new' do

    it 'responds successfully' do
      get :new
      expect(response).to be_success
    end

    it 'should assign a new public body to the view' do
      get :new
      expect(assigns(:public_body)).to be_new_record
    end

    it "builds new translations for all locales" do
      get :new

      translations = assigns[:public_body].
                       translations.map { |t| t.locale.to_s }.sort

      expect(translations).
        to match_array(AlaveteliLocalization.available_locales)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template('new')
    end

    context 'when passed a change request id as a param' do
      render_views

      it 'should populate the name, email address and last edit comment on the public body' do
        change_request = FactoryBot.create(:add_body_request)
        get :new, params: { :change_request_id => change_request.id }
        expect(assigns[:public_body].name).to eq(change_request.public_body_name)
        expect(assigns[:public_body].request_email).to eq(change_request.public_body_email)
        expect(assigns[:public_body].last_edit_comment).to match('Notes: Please')
      end

      it 'should assign a default response text to the view' do
        change_request = FactoryBot.create(:add_body_request)
        get :new, params: { :change_request_id => change_request.id }
        expect(assigns[:change_request_user_response]).to match("Thanks for your suggestion to add A New Body")
      end

    end

  end

  describe "POST #create" do

    context 'on success' do

      before(:each) do
        @params = { :public_body => { :name => 'New Quango',
                                      :short_name => 'nq',
                                      :request_email => 'newquango@localhost',
                                      :tag_string => 'spec',
                                      :last_edit_comment => 'From test code' } }
      end

      it 'creates a new body in the default locale' do
        # FIXME: Can't call PublicBody.destroy_all because database
        # database contstraints prevent them being deleted.
        existing = PublicBody.count
        expected = existing + 1
        expect {
          post :create, params: @params
        }.to change{ PublicBody.count }.from(existing).to(expected)
      end

      it 'can create a public body when the default locale is an underscore locale' do
        AlaveteliLocalization.set_locales('es en_GB', 'en_GB')
        post :create, params: @params
        expect(
          PublicBody.find_by_name('New Quango').translations.first.locale
        ).to eq(:en_GB)
      end

      it 'notifies the admin that the body was created' do
        post :create, params: @params
        expect(flash[:notice]).to eq('PublicBody was successfully created.')
      end

      it 'redirects to the admin page of the body' do
        post :create, params: @params
        expect(response).to redirect_to(admin_body_path(assigns(:public_body)))
      end

    end

    context 'on success for multiple locales' do

      before(:each) do
        @params = { :public_body => { :name => 'New Quango',
                                      :short_name => 'nq',
                                      :request_email => 'newquango@localhost',
                                      :tag_string => 'spec',
                                      :last_edit_comment => 'From test code',
                                      :translations_attributes => {
                                        'es' => { :locale => 'es',
                                                  :name => 'Los Quango',
                                                  :short_name => 'lq' }
        } } }
      end

      it 'saves the body' do
        # FIXME: Can't call PublicBody.destroy_all because database
        # database contstraints prevent them being deleted.
        existing = PublicBody.count
        expected = existing + 1
        expect {
          post :create, params: @params
        }.to change{ PublicBody.count }.from(existing).to(expected)
      end

      it 'saves the default locale translation' do
        post :create, params: @params

        body = PublicBody.find_by_name('New Quango')

        AlaveteliLocalization.with_locale(:en) do
          expect(body.name).to eq('New Quango')
        end
      end

      it 'saves the alternative locale translation' do
        post :create, params: @params

        body = PublicBody.find_by_name('New Quango')

        AlaveteliLocalization.with_locale(:es) do
          expect(body.name).to eq('Los Quango')
          expect(body.url_name).to eq('lq')
          expect(body.first_letter).to eq('L')
        end
      end

    end

    context 'on failure' do

      it 'renders the form if creating the record was unsuccessful' do
        post :create, params: {
                        :public_body => {
                          :name => '',
                          :translations_attributes => {}
                        }
                      }
        expect(response).to render_template('new')
      end

      it 'is rebuilt with the given params' do
        post :create, params: {
                        :public_body => {
                          :name => '',
                          :request_email => 'newquango@localhost',
                          :translations_attributes => {}
                        }
                      }
        expect(assigns(:public_body).request_email).to eq('newquango@localhost')
      end

    end

    context 'on failure for multiple locales' do

      before(:each) do
        @params = { :public_body => { :name => '',
                                      :request_email => 'newquango@localhost',
                                      :translations_attributes => {
                                        'es' => { :locale => 'es',
                                                  :name => 'Los Quango' }
        } } }
      end

      it 'is rebuilt with the default locale translation' do
        post :create, params: @params
        expect(assigns(:public_body)).to_not be_persisted
        expect(assigns(:public_body).request_email).to eq('newquango@localhost')
      end

      it 'is rebuilt with the alternative locale translation' do
        post :create, params: @params

        expect(assigns(:public_body)).to_not be_persisted
        AlaveteliLocalization.with_locale(:es) do
          expect(assigns(:public_body).name).to eq('Los Quango')
        end
      end

    end

    context 'when the body is being created as a result of a change request' do

      before do
        @change_request = FactoryBot.create(:add_body_request)
        post :create,
             params: {
               :public_body => {
                 :name => "New Quango",
                 :short_name => "",
                 :tag_string => "blah",
                 :request_email => 'newquango@localhost',
                 :last_edit_comment => 'From test code'
               },
               :change_request_id => @change_request.id,
               :subject => 'Adding a new body',
               :response =>
                 'The URL will be [Authority URL will be inserted here]'
             }
      end

      it 'should send a response to the requesting user' do
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.subject).to eq('Adding a new body')
        expect(mail.to).to eq([@change_request.get_user_email])
        expect(mail.body).to match(/The URL will be http:\/\/test.host\/body\/new_quango/)
      end

      it 'should mark the change request as closed' do
        expect(PublicBodyChangeRequest.find(@change_request.id).is_open).to be false
      end

    end

  end

  describe "GET #edit" do

    before do
      @body = FactoryBot.create(:public_body)
      AlaveteliLocalization.with_locale('es') do
        @body.name = 'Los Body'
        @body.save!
      end
    end

    it 'responds successfully' do
      get :edit, params: { :id => @body.id }
      expect(response).to be_success
    end

    it 'finds the requested body' do
      get :edit, params: { :id => @body.id }
      expect(assigns[:public_body]).to eq(@body)
    end

    it 'builds new translations if the body does not already have a translation in the specified locale' do
      get :edit, params: { :id => @body.id }
      expect(assigns[:public_body].translations.map(&:locale)).to include(:fr)
    end

    it 'renders the edit template' do
      get :edit, params: { :id => @body.id }
      expect(response).to render_template('edit')
    end

    it "edits a public body in another locale" do
      get :edit, params: { :id => 3, :locale => :en }

      # When editing a body, the controller returns all available translations
      expect(assigns[:public_body].find_translation_by_locale("es").name).to eq('El Department for Humpadinking')
      expect(assigns[:public_body].name).to eq('Department for Humpadinking')
      expect(response).to render_template('edit')
    end

    context 'when passed a change request id as a param' do
      render_views

      before do
        @change_request = FactoryBot.create(:update_body_request)
        get :edit, params: {
                     :id => @change_request.public_body_id,
                     :change_request_id => @change_request.id
                   }
      end

      it 'should populate the email address and last edit comment on the public body' do
        change_request = FactoryBot.create(:update_body_request)
        get :edit, params: {
                     :id => change_request.public_body_id,
                     :change_request_id => change_request.id
                   }
        expect(assigns[:public_body].request_email).to eq(@change_request.public_body_email)
        expect(assigns[:public_body].last_edit_comment).to match('Notes: Please')
      end

      it 'should assign a default response text to the view' do
        expect(assigns[:change_request_user_response]).to match("Thanks for your suggestion to update the email address")
      end
    end

  end

  describe "POST #update" do

    before do
      @body = FactoryBot.create(:public_body)
      AlaveteliLocalization.with_locale('es') do
        @body.name = 'Los Quango'
        @body.save!
      end

      @params = { :id => @body.id,
                  :public_body => { :name => 'Renamed',
                                    :short_name => @body.short_name,
                                    :request_email => @body.request_email,
                                    :tag_string => @body.tag_string,
                                    :last_edit_comment => 'From test code',
                                    :translations_attributes => {
                                      'es' => { :id => @body.translation_for(:es).id,
                                                :locale => 'es',
                                                :title => @body.name(:es) }
      } } }
    end

    it 'finds the heading to update' do
      post :update, params: @params
      expect(assigns(:heading)).to eq(@heading)
    end

    context 'on success' do

      it 'saves edits to a public body heading' do
        post :update, params: @params
        body = PublicBody.find(@body.id)
        expect(body.name).to eq('Renamed')
      end

      it 'notifies the admin that the body was updated' do
        post :update, params: @params
        expect(flash[:notice]).to eq('PublicBody was successfully updated.')
      end

      it 'redirects to the admin body page' do
        post :update, params: @params
        expect(response).to redirect_to(admin_body_path(@body))
      end

    end

    context 'on success for multiple locales' do

      it 'saves edits to a public body heading in another locale' do
        expect(@body.name(:es)).to eq('Los Quango')
        post :update, params: {
                        :id => @body.id,
                        :public_body => {
                          :name => @body.name(:en),
                          :translations_attributes => {
                            'es' => {
                              :id => @body.translation_for(:es).id,
                              :locale => 'es',
                              :name => 'Renamed'
                            }
                          }
                        }
                      }

        body = PublicBody.find(@body.id)
        expect(body.name(:es)).to eq('Renamed')
        expect(body.name(:en)).to eq(@body.name(:en))
      end

      it 'adds a new translation' do
        @body.translation_for(:es).destroy
        @body.reload

        put :update, params: {
                       :id => @body.id,
                       :public_body => {
                         :name => @body.name(:en),
                         :translations_attributes => {
                           'es' => {
                             :locale => "es",
                             :name => "Example Public Body ES"
                           }
                         }
                       }
                     }

        expect(request.flash[:notice]).to include('successful')

        body = PublicBody.find(@body.id)

        AlaveteliLocalization.with_locale(:es) do
          expect(body.name).to eq('Example Public Body ES')
        end
      end

      it 'creates a new translation for the default locale' do
        AlaveteliLocalization.set_locales('es en_GB', 'en_GB')
        put :update, params: {
                       :id => @body.id,
                       :public_body => {
                         :name => "Example Public Body en_GB"
                       }
                     }

        body = PublicBody.find(@body.id)
        expect(body.translations.map(&:locale)).to include(:en_GB)
      end

      it 'adds new translations' do
        @body.translation_for(:es).destroy
        @body.reload

        post :update, params: {
                        :id => @body.id,
                        :public_body => {
                          :name => @body.name(:en),
                          :translations_attributes => {
                            'es' => {
                              :locale => "es",
                              :name => "Example Public Body ES"
                            },
                            'fr' => {
                              :locale => "fr",
                              :name => "Example Public Body FR"
                            }
                          }
                        }
                      }

        expect(request.flash[:notice]).to include('successful')

        body = PublicBody.find(@body.id)

        AlaveteliLocalization.with_locale(:es) do
          expect(body.name).to eq('Example Public Body ES')
        end
        AlaveteliLocalization.with_locale(:fr) do
          expect(body.name).to eq('Example Public Body FR')
        end
      end

      it 'updates an existing translation and adds a third translation' do
        post :update, params: {
          :id => @body.id,
          :public_body => {
            :name => @body.name(:en),
            :translations_attributes => {
              # Update existing translation
              'es' => { :id => @body.translation_for(:es).id,
                        :locale => "es",
                        :name => "Renamed Example Public Body ES" },
              # Add new translation
              'fr' => { :locale => "fr",
                        :name => "Example Public Body FR" }
            }
          }
        }

        expect(request.flash[:notice]).to include('successful')

        body = PublicBody.find(@body.id)

        AlaveteliLocalization.with_locale(:es) do
          expect(body.name).to eq('Renamed Example Public Body ES')
        end
        AlaveteliLocalization.with_locale(:fr) do
          expect(body.name).to eq('Example Public Body FR')
        end
      end

    end

    context 'on failure' do

      it 'renders the form if creating the record was unsuccessful' do
        post :update, params: {
                        :id => @body.id,
                        :public_body => {
                          :name => '',
                          :translations_attributes => {}
                        }
                      }
        expect(response).to render_template('edit')
      end

      it 'is rebuilt with the given params' do
        post :update, params: {
                        :id => @body.id,
                        :public_body => {
                          :name => '',
                          :request_email => 'updated@localhost',
                          :translations_attributes => {}
                        }
                      }
        expect(assigns(:public_body).request_email).to eq('updated@localhost')
      end

    end

    context 'on failure for multiple locales' do

      before(:each) do
        @params = { :id => @body.id,
                    :public_body => { :name => '',
                                      :translations_attributes => {
                                        'es' => { :id => @body.translation_for(:es).id,
                                                  :locale => 'es',
                                                  :name => 'Mi Nuevo Body' }
        } } }
      end

      it 'is rebuilt with the default locale translation' do
        post :update, params: @params
        expect(assigns(:public_body).name(:en)).to be_nil
      end

      it 'is rebuilt with the alternative locale translation' do
        post :update, params: @params

        AlaveteliLocalization.with_locale(:es) do
          expect(assigns(:public_body).name).to eq('Mi Nuevo Body')
        end
      end

    end

    context 'when the body is being updated as a result of a change request' do

      before do
        @change_request = FactoryBot.create(:update_body_request)
        post :update, params: {
                        :id => @change_request.public_body_id,
                        :public_body => {
                          :name => "New Quango",
                          :short_name => "",
                          :request_email => 'newquango@localhost',
                          :last_edit_comment => 'From test code'
                        },
                        :change_request_id => @change_request.id,
                        :subject => 'Body update',
                        :response => 'Done.'
                      }
      end

      it 'should send a response to the requesting user' do
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.subject).to eq('Body update')
        expect(mail.to).to eq([@change_request.get_user_email])
        expect(mail.body).to match(/Done./)
      end

      it 'should mark the change request as closed' do
        expect(PublicBodyChangeRequest.find(@change_request.id).is_open).to be false
      end

    end
  end

  describe "POST #destroy" do

    it "does not destroy a public body that has associated requests" do
      id = public_bodies(:humpadink_public_body).id
      n = PublicBody.count
      post :destroy, params: { :id => id }
      expect(response).to redirect_to(:controller=>'admin_public_body', :action=>'show', :id => id)
      expect(PublicBody.count).to eq(n)
    end

    it "destroys a public body" do
      n = PublicBody.count
      post :destroy, params: { :id => public_bodies(:forlorn_public_body).id }
      expect(response).to redirect_to admin_bodies_path
      expect(PublicBody.count).to eq(n - 1)
    end

  end


  describe "POST #mass_tag_add" do

    it "mass assigns tags" do
      condition = "public_body_translations.locale = ?"
      n = PublicBody.joins(:translations).where([condition, "en"]).count
      post :mass_tag_add, params: {
                            :new_tag => "department",
                            :table_name => "substring"
                          }
      expect(request.flash[:notice]).to eq("Added tag to table of bodies.")
      expect(response).to redirect_to admin_bodies_path
      expect(PublicBody.find_by_tag("department").count).to eq(n)
    end
  end

  describe "GET #import_csv" do

    describe 'when handling a GET request' do

      it 'should get the page successfully' do
        get :import_csv
        expect(response).to be_success
      end

    end

    describe 'when handling a POST request' do

      before do
        allow(PublicBody).to receive(:import_csv).and_return([[],[]])
        @file_object = fixture_file_upload('/files/fake-authority-type.csv')
      end

      it 'should handle a nil csv file param' do
        post :import_csv, params: { :commit => 'Dry run' }
        expect(response).to be_success
      end

      describe 'if there is a csv file param' do

        it 'should assign the original filename to the view' do
          post :import_csv, params: {
                              :csv_file => @file_object,
                              :commit => 'Dry run'
                            }
          expect(assigns[:original_csv_file]).to eq('fake-authority-type.csv')
        end

      end

      describe 'if there is no csv file param, but there are temporary_csv_file and original_csv_file params' do

        it 'should try and get the file contents from a temporary file whose name is passed as a param' do
          expect(@controller).to receive(:retrieve_csv_data).with('csv_upload-2046-12-31-394')
          post :import_csv,
               params: {
                 :temporary_csv_file => 'csv_upload-2046-12-31-394',
                 :original_csv_file => 'original_contents.txt',
                 :commit => 'Dry run'
               }
        end

        it 'should raise an error on an invalid temp file name' do
          params = { :temporary_csv_file => 'bad_name',
                     :original_csv_file => 'original_contents.txt',
                     :commit => 'Dry run'}
          expected_error = "Invalid filename in upload_csv: bad_name"
          expect {
            post :import_csv, params: params
          }.to raise_error(expected_error)
        end

        it 'should raise an error if the temp file does not exist' do
          temp_name = "csv_upload-20461231-394"
          params = { :temporary_csv_file => temp_name,
                     :original_csv_file => 'original_contents.txt',
                     :commit => 'Dry run'}
          expected_error = "Missing file in upload_csv: csv_upload-20461231-394"
          expect {
            post :import_csv, params: params
          }.to raise_error(expected_error)
        end

        it 'should assign the temporary filename to the view' do
          post :import_csv, params: {
                              :csv_file => @file_object,
                              :commit => 'Dry run'
                            }
          temporary_filename = assigns[:temporary_csv_file]
          expect(temporary_filename).to match(/csv_upload-#{Time.zone.now.strftime("%Y%m%d")}-\d{1,5}/)
        end

      end
    end
  end

  describe "when administering public bodies and paying attention to authentication" do

    before do
      config = MySociety::Config.load_default
      config['SKIP_ADMIN_AUTH'] = false
      basic_auth_login @request
    end

    after do
      config = MySociety::Config.load_default
      config['SKIP_ADMIN_AUTH'] = true
    end

    def setup_emergency_credentials(username, password)
      config = MySociety::Config.load_default
      config['SKIP_ADMIN_AUTH'] = false
      config['ADMIN_USERNAME'] = username
      config['ADMIN_PASSWORD'] = password
      @request.env["HTTP_AUTHORIZATION"] = ""
    end

    it "disallows non-authenticated users to do anything" do
      @request.env["HTTP_AUTHORIZATION"] = ""
      n = PublicBody.count
      post :destroy, params: { :id => 3 }
      expect(response).
        to redirect_to(signin_path(:token => get_last_post_redirect.token))
      expect(PublicBody.count).to eq(n)
      expect(session[:using_admin]).to eq(nil)
    end

    it "skips admin authorisation when SKIP_ADMIN_AUTH set" do
      config = MySociety::Config.load_default
      config['SKIP_ADMIN_AUTH'] = true
      @request.env["HTTP_AUTHORIZATION"] = ""
      n = PublicBody.count
      post :destroy, params: { :id => public_bodies(:forlorn_public_body).id }
      expect(PublicBody.count).to eq(n - 1)
      expect(session[:using_admin]).to eq(1)
    end

    it "doesn't let people with bad emergency account credentials log in" do
      setup_emergency_credentials('biz', 'fuz')
      n = PublicBody.count
      basic_auth_login(@request, "baduser", "badpassword")
      post :destroy, params: { :id => public_bodies(:forlorn_public_body).id }
      expect(response).
        to redirect_to(signin_path(:token => get_last_post_redirect.token))
      expect(PublicBody.count).to eq(n)
      expect(session[:using_admin]).to eq(nil)
    end

    it "allows people with good emergency account credentials log in using HTTP Basic Auth" do
      setup_emergency_credentials('biz', 'fuz')
      n = PublicBody.count
      basic_auth_login(@request, "biz", "fuz")
      post :show, params: {
                    :id => public_bodies(:humpadink_public_body).id,
                    :emergency => 1
                  }
      expect(session[:using_admin]).to eq(1)
      n = PublicBody.count
      post :destroy, params: {:id => public_bodies(:forlorn_public_body).id }
      expect(session[:using_admin]).to eq(1)
      expect(PublicBody.count).to eq(n - 1)
    end

    it "doesn't let people with good emergency account credentials log in if the emergency user is disabled" do
      setup_emergency_credentials('biz', 'fuz')
      allow(AlaveteliConfiguration).to receive(:disable_emergency_user).and_return(true)
      n = PublicBody.count
      basic_auth_login(@request, "biz", "fuz")
      post :show, params: { :id => public_bodies(:humpadink_public_body).id,
                            :emergency => 1 }
      expect(session[:using_admin]).to eq(nil)
      n = PublicBody.count
      post :destroy, params: { :id => public_bodies(:forlorn_public_body).id }
      expect(session[:using_admin]).to eq(nil)
      expect(PublicBody.count).to eq(n)
    end

    it "allows superusers to do stuff" do
      session[:user_id] = users(:admin_user).id
      @request.env["HTTP_AUTHORIZATION"] = ""
      n = PublicBody.count
      post :destroy, params: { :id => public_bodies(:forlorn_public_body).id }
      expect(PublicBody.count).to eq(n - 1)
      expect(session[:using_admin]).to eq(1)
    end

    it "doesn't allow non-superusers to do stuff" do
      session[:user_id] = users(:robin_user).id
      @request.env["HTTP_AUTHORIZATION"] = ""
      n = PublicBody.count
      post :destroy, params: { :id => public_bodies(:forlorn_public_body).id }
      expect(response).
        to redirect_to(signin_path(:token => get_last_post_redirect.token))
      expect(PublicBody.count).to eq(n)
      expect(session[:using_admin]).to eq(nil)
    end

    describe 'when asked for the admin current user' do

      it 'returns the emergency account name for someone who logged in with the emergency account' do
        setup_emergency_credentials('biz', 'fuz')
        basic_auth_login(@request, "biz", "fuz")
        post :show, params: { :id => public_bodies(:humpadink_public_body).id,
                              :emergency => 1 }
        expect(controller.send(:admin_current_user)).to eq('biz')
      end

      it 'returns the current user url_name for a superuser' do
        session[:user_id] = users(:admin_user).id
        @request.env["HTTP_AUTHORIZATION"] = ""
        post :show, params: { :id => public_bodies(:humpadink_public_body).id }
        expect(controller.send(:admin_current_user)).to eq(users(:admin_user).url_name)
      end

      it 'returns the REMOTE_USER value from the request environment when skipping admin auth' do
        config = MySociety::Config.load_default
        config['SKIP_ADMIN_AUTH'] = true
        @request.env["HTTP_AUTHORIZATION"] = ""
        @request.env["REMOTE_USER"] = "i_am_admin"
        post :show, params: { :id => public_bodies(:humpadink_public_body).id }
        expect(controller.send(:admin_current_user)).to eq("i_am_admin")
      end

    end
  end
end

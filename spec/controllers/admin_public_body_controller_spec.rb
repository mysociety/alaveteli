# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminPublicBodyController, "when showing the index of public bodies" do
    render_views

    it "shows the index page" do
        get :index
    end

    it "searches for 'humpa'" do
        get :index, :query => "humpa"
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
    end

    it "searches for 'humpa' in another locale" do
        get :index, {:query => "humpa", :locale => "es"}
        assigns[:public_bodies].should == [ public_bodies(:humpadink_public_body) ]
    end

end

describe AdminPublicBodyController, "when showing a public body" do
    render_views

    it "shows a public body" do
        get :show, :id => 2
    end

    it "sets a using_admin flag" do
        get :show, :id => 2
        session[:using_admin].should == 1
    end

    it "shows a public body in another locale" do
        get :show, {:id => 2, :locale => "es" }
    end

end

describe AdminPublicBodyController, 'when showing the form for a new public body' do

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

        translations = assigns[:public_body].translations.map{ |t| t.locale.to_s }.sort
        available = I18n.available_locales.map{ |l| l.to_s }.sort

        expect(translations).to eq(available)
    end

    it 'renders the new template' do
        get :new
        expect(response).to render_template('new')
    end

    context 'when passed a change request id as a param' do
        render_views

        it 'should populate the name, email address and last edit comment on the public body' do
            change_request = FactoryGirl.create(:add_body_request)
            get :new, :change_request_id => change_request.id
            assigns[:public_body].name.should == change_request.public_body_name
            assigns[:public_body].request_email.should == change_request.public_body_email
            assigns[:public_body].last_edit_comment.should match('Notes: Please')
        end

        it 'should assign a default response text to the view' do
            change_request = FactoryGirl.create(:add_body_request)
            get :new, :change_request_id => change_request.id
            assigns[:change_request_user_response].should match("Thanks for your suggestion to add A New Body")
        end
    end

end

describe AdminPublicBodyController, "when creating a public body" do
    render_views

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
              post :create, @params
            }.to change{ PublicBody.count }.from(existing).to(expected)
        end

        it 'notifies the admin that the body was created' do
            post :create, @params
            expect(flash[:notice]).to eq('PublicBody was successfully created.')
        end

        it 'redirects to the admin page of the body' do
            post :create, @params
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
                                                    :name => 'Los Quango' }
                                        } } }
        end

        it 'saves the body' do
          # FIXME: Can't call PublicBody.destroy_all because database
          # database contstraints prevent them being deleted.
          existing = PublicBody.count
          expected = existing + 1
            expect {
              post :create, @params
            }.to change{ PublicBody.count }.from(existing).to(expected)
        end

        it 'saves the default locale translation' do
            post :create, @params

            body = PublicBody.find_by_name('New Quango')

            I18n.with_locale(:en) do
                expect(body.name).to eq('New Quango')
            end
        end

        it 'saves the alternative locale translation' do
            post :create, @params

            body = PublicBody.find_by_name('New Quango')

            I18n.with_locale(:es) do
                expect(body.name).to eq('Los Quango')
            end
        end

    end

    context 'on failure' do

        it 'renders the form if creating the record was unsuccessful' do
            post :create, :public_body => { :name => '',
                                            :translations_attributes => {} }
            expect(response).to render_template('new')
        end

        it 'is rebuilt with the given params' do
            post :create, :public_body => { :name => '',
                                            :request_email => 'newquango@localhost',
                                            :translations_attributes => {} }
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
            post :create, @params
            expect(assigns(:public_body)).to_not be_persisted
            expect(assigns(:public_body).request_email).to eq('newquango@localhost')
        end

        it 'is rebuilt with the alternative locale translation' do
            post :create, @params

            expect(assigns(:public_body)).to_not be_persisted
            I18n.with_locale(:es) do
                expect(assigns(:public_body).name).to eq('Los Quango')
            end
        end

    end

    context 'when the body is being created as a result of a change request' do

        before do
            @change_request = FactoryGirl.create(:add_body_request)
            post :create, { :public_body => { :name => "New Quango",
                                              :short_name => "",
                                              :tag_string => "blah",
                                              :request_email => 'newquango@localhost',
                                              :last_edit_comment => 'From test code' },
                            :change_request_id => @change_request.id,
                            :subject => 'Adding a new body',
                            :response => 'The URL will be [Authority URL will be inserted here]'}
        end

        it 'should send a response to the requesting user' do
            deliveries = ActionMailer::Base.deliveries
            deliveries.size.should == 1
            mail = deliveries[0]
            mail.subject.should == 'Adding a new body'
            mail.to.should == [@change_request.get_user_email]
            mail.body.should =~ /The URL will be http:\/\/test.host\/body\/new_quango/
        end

        it 'should mark the change request as closed' do
            PublicBodyChangeRequest.find(@change_request.id).is_open.should be_false
        end

    end

end

describe AdminPublicBodyController, "when editing a public body" do
    render_views

    before do
        @body = FactoryGirl.create(:public_body)
        I18n.with_locale('es') do
            @body.name = 'Los Body'
            @body.save!
        end
    end

    it 'responds successfully' do
        get :edit, :id => @body.id
        expect(response).to be_success
    end

    it 'finds the requested body' do
        get :edit, :id => @body.id
        expect(assigns[:public_body]).to eq(@body)
    end

    it 'builds new translations if the body does not already have a translation in the specified locale' do
        get :edit, :id => @body.id
        expect(assigns[:public_body].translations.map(&:locale)).to include(:fr)
    end

    it 'renders the edit template' do
        get :edit, :id => @body.id
        expect(response).to render_template('edit')
    end
  
    it "edits a public body in another locale" do
        get :edit, {:id => 3, :locale => :en}

        # When editing a body, the controller returns all available translations
        assigns[:public_body].find_translation_by_locale("es").name.should == 'El Department for Humpadinking'
        assigns[:public_body].name.should == 'Department for Humpadinking'
        response.should render_template('edit')
    end

    context 'when passed a change request id as a param' do
        render_views

        before do
            @change_request = FactoryGirl.create(:update_body_request)
            get :edit, :id => @change_request.public_body_id,  :change_request_id => @change_request.id
        end

        it 'should populate the email address and last edit comment on the public body' do
            change_request = FactoryGirl.create(:update_body_request)
            get :edit, :id => change_request.public_body_id,  :change_request_id => change_request.id
            assigns[:public_body].request_email.should == @change_request.public_body_email
            assigns[:public_body].last_edit_comment.should match('Notes: Please')
        end

        it 'should assign a default response text to the view' do
            assigns[:change_request_user_response].should match("Thanks for your suggestion to update the email address")
        end
    end

end

describe AdminPublicBodyController, "when updating a public body" do
    render_views

    before do
        @body = FactoryGirl.create(:public_body)
        I18n.with_locale('es') do
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
        post :update, @params
        expect(assigns(:heading)).to eq(@heading)
    end

    context 'on success' do

        it 'saves edits to a public body heading' do
            post :update, @params
            body = PublicBody.find(@body.id)
            expect(body.name).to eq('Renamed')
        end

        it 'notifies the admin that the body was updated' do
            post :update, @params
            expect(flash[:notice]).to eq('PublicBody was successfully updated.')
        end

        it 'redirects to the admin body page' do
            post :update, @params
            expect(response).to redirect_to(admin_body_path(@body))
        end

    end

    context 'on success for multiple locales' do

        it 'saves edits to a public body heading in another locale' do
            @body.name(:es).should == 'Los Quango'
            post :update, :id => @body.id,
                          :public_body => {
                              :name => @body.name(:en),
                              :translations_attributes => {
                                'es' => { :id => @body.translation_for(:es).id,
                                          :locale => 'es',
                                          :name => 'Renamed' }
                              }
                          }

            body = PublicBody.find(@body.id)
            expect(body.name(:es)).to eq('Renamed')
            expect(body.name(:en)).to eq(@body.name(:en))
        end

        it 'adds a new translation' do
             @body.translation_for(:es).destroy
             @body.reload

             put :update, {
                 :id => @body.id,
                 :public_body => {
                     :name => @body.name(:en),
                     :translations_attributes => {
                         'es' => { :locale => "es",
                                   :name => "Example Public Body ES" }
                     }
                 }
             }

             request.flash[:notice].should include('successful')

             body = PublicBody.find(@body.id)

             I18n.with_locale(:es) do
                expect(body.name).to eq('Example Public Body ES')
             end
         end

         it 'adds new translations' do
             @body.translation_for(:es).destroy
             @body.reload

             post :update, {
                 :id => @body.id,
                 :public_body => {
                     :name => @body.name(:en),
                     :translations_attributes => {
                         'es' => { :locale => "es",
                                   :name => "Example Public Body ES" },
                         'fr' => { :locale => "fr",
                                   :name => "Example Public Body FR" }
                     }
                 }
             }

             request.flash[:notice].should include('successful')

             body = PublicBody.find(@body.id)

             I18n.with_locale(:es) do
                expect(body.name).to eq('Example Public Body ES')
             end
             I18n.with_locale(:fr) do
                expect(body.name).to eq('Example Public Body FR')
             end
         end

         it 'updates an existing translation and adds a third translation' do
             post :update, {
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

             request.flash[:notice].should include('successful')

             body = PublicBody.find(@body.id)

             I18n.with_locale(:es) do
                expect(body.name).to eq('Renamed Example Public Body ES')
             end
             I18n.with_locale(:fr) do
                expect(body.name).to eq('Example Public Body FR')
             end
         end

    end

    context 'on failure' do

        it 'renders the form if creating the record was unsuccessful' do
            post :update, :id => @body.id,
                          :public_body => {
                            :name => '',
                            :translations_attributes => {}
                          }
            expect(response).to render_template('edit')
        end

        it 'is rebuilt with the given params' do
            post :update, :id => @body.id,
                          :public_body => {
                            :name => '',
                            :request_email => 'updated@localhost',
                            :translations_attributes => {}
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
            post :update, @params
            expect(assigns(:public_body).name(:en)).to eq('')
        end

        it 'is rebuilt with the alternative locale translation' do
            post :update, @params

            I18n.with_locale(:es) do
                expect(assigns(:public_body).name).to eq('Mi Nuevo Body')
            end
        end

    end

    context 'when the body is being updated as a result of a change request' do

        before do
            @change_request = FactoryGirl.create(:update_body_request)
            post :update, { :id => @change_request.public_body_id,
                            :public_body => { :name => "New Quango",
                                              :short_name => "",
                                              :request_email => 'newquango@localhost',
                                              :last_edit_comment => 'From test code' },
                            :change_request_id => @change_request.id,
                            :subject => 'Body update',
                            :response => 'Done.'}
        end

        it 'should send a response to the requesting user' do
            deliveries = ActionMailer::Base.deliveries
            deliveries.size.should == 1
            mail = deliveries[0]
            mail.subject.should == 'Body update'
            mail.to.should == [@change_request.get_user_email]
            mail.body.should =~ /Done./
        end

        it 'should mark the change request as closed' do
            PublicBodyChangeRequest.find(@change_request.id).is_open.should be_false
        end

    end
end

describe AdminPublicBodyController, "when destroying a public body" do
    render_views

    it "does not destroy a public body that has associated requests" do
        id = public_bodies(:humpadink_public_body).id
        n = PublicBody.count
        post :destroy, { :id => id }
        response.should redirect_to(:controller=>'admin_public_body', :action=>'show', :id => id)
        PublicBody.count.should == n
    end

    it "destroys a public body" do
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        response.should redirect_to admin_bodies_path
        PublicBody.count.should == n - 1
    end

end

describe AdminPublicBodyController, "when assigning public body tags" do
    render_views

    it "mass assigns tags" do
        condition = "public_body_translations.locale = ?"
        n = PublicBody.joins(:translations).where([condition, "en"]).count
        post :mass_tag_add, { :new_tag => "department", :table_name => "substring" }
        request.flash[:notice].should == "Added tag to table of bodies."
        response.should redirect_to admin_bodies_path
        PublicBody.find_by_tag("department").count.should == n
    end
end

describe AdminPublicBodyController, "when importing a csv" do
    render_views

    describe 'when handling a GET request' do

        it 'should get the page successfully' do
            get :import_csv
            response.should be_success
        end

    end

    describe 'when handling a POST request' do

        before do
            PublicBody.stub!(:import_csv).and_return([[],[]])
            @file_object = fixture_file_upload('/files/fake-authority-type.csv')
        end

        it 'should handle a nil csv file param' do
            post :import_csv, { :commit => 'Dry run' }
            response.should be_success
        end

        describe 'if there is a csv file param' do

            it 'should try to get the contents and original name of a csv file param' do
                @file_object.should_receive(:read).and_return('some contents')
                post :import_csv, { :csv_file => @file_object,
                                    :commit => 'Dry run'}
            end

            it 'should assign the original filename to the view' do
                post :import_csv, { :csv_file => @file_object,
                                    :commit => 'Dry run'}
                assigns[:original_csv_file].should == 'fake-authority-type.csv'
            end

        end

        describe 'if there is no csv file param, but there are temporary_csv_file and
                  original_csv_file params' do

            it 'should try and get the file contents from a temporary file whose name
                is passed as a param' do
                @controller.should_receive(:retrieve_csv_data).with('csv_upload-2046-12-31-394')
                post :import_csv, { :temporary_csv_file => 'csv_upload-2046-12-31-394',
                                    :original_csv_file => 'original_contents.txt',
                                    :commit => 'Dry run'}
            end

            it 'should raise an error on an invalid temp file name' do
                params = { :temporary_csv_file => 'bad_name',
                           :original_csv_file => 'original_contents.txt',
                           :commit => 'Dry run'}
                expected_error = "Invalid filename in upload_csv: bad_name"
                lambda{ post :import_csv, params }.should raise_error(expected_error)
            end

            it 'should raise an error if the temp file does not exist' do
                temp_name = "csv_upload-20461231-394"
                params = { :temporary_csv_file => temp_name,
                           :original_csv_file => 'original_contents.txt',
                           :commit => 'Dry run'}
                expected_error = "Missing file in upload_csv: csv_upload-20461231-394"
                lambda{ post :import_csv, params }.should raise_error(expected_error)
            end

            it 'should assign the temporary filename to the view' do
                post :import_csv, { :csv_file => @file_object,
                                    :commit => 'Dry run'}
                temporary_filename = assigns[:temporary_csv_file]
                temporary_filename.should match(/csv_upload-#{Time.now.strftime("%Y%m%d")}-\d{1,5}/)
            end

        end
    end
end

describe AdminPublicBodyController, "when administering public bodies and paying attention to authentication" do

    render_views

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
        post :destroy, { :id => 3 }
        response.should redirect_to(:controller=>'user', :action=>'signin', :token=>PostRedirect.get_last_post_redirect.token)
        PublicBody.count.should == n
        session[:using_admin].should == nil
    end

    it "skips admin authorisation when SKIP_ADMIN_AUTH set" do
        config = MySociety::Config.load_default
        config['SKIP_ADMIN_AUTH'] = true
        @request.env["HTTP_AUTHORIZATION"] = ""
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        PublicBody.count.should == n - 1
        session[:using_admin].should == 1
    end

    it "doesn't let people with bad emergency account credentials log in" do
        setup_emergency_credentials('biz', 'fuz')
        n = PublicBody.count
        basic_auth_login(@request, "baduser", "badpassword")
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        response.should redirect_to(:controller=>'user', :action=>'signin', :token=>PostRedirect.get_last_post_redirect.token)
        PublicBody.count.should == n
        session[:using_admin].should == nil
    end

    it "allows people with good emergency account credentials log in using HTTP Basic Auth" do
        setup_emergency_credentials('biz', 'fuz')
        n = PublicBody.count
        basic_auth_login(@request, "biz", "fuz")
        post :show, { :id => public_bodies(:humpadink_public_body).id, :emergency => 1}
        session[:using_admin].should == 1
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        session[:using_admin].should == 1
        PublicBody.count.should == n - 1
    end

    it "doesn't let people with good emergency account credentials log in if the emergency user is disabled" do
        setup_emergency_credentials('biz', 'fuz')
        AlaveteliConfiguration.stub!(:disable_emergency_user).and_return(true)
        n = PublicBody.count
        basic_auth_login(@request, "biz", "fuz")
        post :show, { :id => public_bodies(:humpadink_public_body).id, :emergency => 1}
        session[:using_admin].should == nil
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        session[:using_admin].should == nil
        PublicBody.count.should == n
    end

    it "allows superusers to do stuff" do
        session[:user_id] = users(:admin_user).id
        @request.env["HTTP_AUTHORIZATION"] = ""
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        PublicBody.count.should == n - 1
        session[:using_admin].should == 1
    end

    it "doesn't allow non-superusers to do stuff" do
        session[:user_id] = users(:robin_user).id
        @request.env["HTTP_AUTHORIZATION"] = ""
        n = PublicBody.count
        post :destroy, { :id => public_bodies(:forlorn_public_body).id }
        response.should redirect_to(:controller=>'user', :action=>'signin', :token=>PostRedirect.get_last_post_redirect.token)
        PublicBody.count.should == n
        session[:using_admin].should == nil
    end

    describe 'when asked for the admin current user' do

        it 'returns the emergency account name for someone who logged in with the emergency account' do
            setup_emergency_credentials('biz', 'fuz')
            basic_auth_login(@request, "biz", "fuz")
            post :show, { :id => public_bodies(:humpadink_public_body).id, :emergency => 1 }
            controller.send(:admin_current_user).should == 'biz'
        end

        it 'returns the current user url_name for a superuser' do
            session[:user_id] = users(:admin_user).id
            @request.env["HTTP_AUTHORIZATION"] = ""
            post :show, { :id => public_bodies(:humpadink_public_body).id }
            controller.send(:admin_current_user).should == users(:admin_user).url_name
        end

        it 'returns the REMOTE_USER value from the request environment when skipping admin auth' do
            config = MySociety::Config.load_default
            config['SKIP_ADMIN_AUTH'] = true
            @request.env["HTTP_AUTHORIZATION"] = ""
            @request.env["REMOTE_USER"] = "i_am_admin"
            post :show, { :id => public_bodies(:humpadink_public_body).id }
            controller.send(:admin_current_user).should == "i_am_admin"
        end

    end
end


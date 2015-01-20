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

    it 'should assign a new public body to the view' do
        get :new
        assigns[:public_body].should be_a(PublicBody)
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

    it "creates a new public body in one locale" do
        n = PublicBody.count
        post :create, { :public_body => { :name => "New Quango",
                                          :short_name => "",
                                          :tag_string => "blah",
                                          :request_email => 'newquango@localhost',
                                          :last_edit_comment => 'From test code' } }
        PublicBody.count.should == n + 1

        body = PublicBody.find_by_name("New Quango")
        response.should redirect_to(:controller=>'admin_public_body', :action=>'show', :id=>body.id)
    end

    it "creates a new public body with multiple locales" do
        n = PublicBody.count
        post :create, {
            :public_body => { :name => "New Quango",
                              :short_name => "",
                              :tag_string => "blah",
                              :request_email => 'newquango@localhost',
                              :last_edit_comment => 'From test code',
                              :translations_attributes => {
                                  'es' => { :locale => "es",
                                            :name => "Mi Nuevo Quango",
                                            :short_name => "",
                                            :request_email => 'newquango@localhost' }
                              }
            }
        }
        PublicBody.count.should == n + 1

        body = PublicBody.find_by_name("New Quango")
        body.translations.map {|t| t.locale.to_s}.sort.should == ["en", "es"]
        I18n.with_locale(:en) do
            body.name.should == "New Quango"
            body.url_name.should == "new_quango"
            body.first_letter.should == "N"
        end
        I18n.with_locale(:es) do
            body.name.should == "Mi Nuevo Quango"
            body.url_name.should == "mi_nuevo_quango"
            body.first_letter.should == "M"
        end

        response.should redirect_to(:controller=>'admin_public_body', :action=>'show', :id=>body.id)
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

    it "edits a public body" do
        get :edit, :id => 2
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

    it "saves edits to a public body" do
        public_bodies(:humpadink_public_body).name.should == "Department for Humpadinking"
        post :update, { :id => 3, :public_body => { :name => "Renamed",
                                                    :short_name => "",
                                                    :tag_string => "some tags",
                                                    :request_email => 'edited@localhost',
                                                    :last_edit_comment => 'From test code' } }
        request.flash[:notice].should include('successful')
        pb = PublicBody.find(public_bodies(:humpadink_public_body).id)
        pb.name.should == "Renamed"
    end

    it 'adds a new translation' do
        pb = public_bodies(:humpadink_public_body)
        pb.translation_for(:es).destroy
        pb.reload

        post :update, {
            :id => pb.id,
            :public_body => {
                :name => "Department for Humpadinking",
                :short_name => "",
                :tag_string => "some tags",
                :request_email => 'edited@localhost',
                :last_edit_comment => 'From test code',
                :translations_attributes => {
                    'es' => { :locale => "es",
                              :name => "El Department for Humpadinking",
                              :short_name => "",
                              :request_email => 'edited@localhost' }
                }
            }
        }

        request.flash[:notice].should include('successful')

        pb = PublicBody.find(public_bodies(:humpadink_public_body).id)

        I18n.with_locale(:es) do
           expect(pb.name).to eq('El Department for Humpadinking')
        end
    end

    it 'adds new translations' do
        pb = public_bodies(:humpadink_public_body)
        pb.translation_for(:es).destroy
        pb.reload

        post :update, {
            :id => pb.id,
            :public_body => {
                :name => "Department for Humpadinking",
                :short_name => "",
                :tag_string => "some tags",
                :request_email => 'edited@localhost',
                :last_edit_comment => 'From test code',
                :translations_attributes => {
                    'es' => { :locale => "es",
                              :name => "El Department for Humpadinking",
                              :short_name => "",
                              :request_email => 'edited@localhost' },
                    'fr' => { :locale => "fr",
                              :name => "Le Department for Humpadinking",
                              :short_name => "",
                              :request_email => 'edited@localhost' }
                }
            }
        }

        request.flash[:notice].should include('successful')

        pb = PublicBody.find(public_bodies(:humpadink_public_body).id)

        I18n.with_locale(:es) do
           expect(pb.name).to eq('El Department for Humpadinking')
        end

        I18n.with_locale(:fr) do
           expect(pb.name).to eq('Le Department for Humpadinking')
        end
    end

    it 'updates an existing translation and adds a third translation' do
        pb = public_bodies(:humpadink_public_body)

        put :update, {
            :id => pb.id,
            :public_body => {
                :name => "Department for Humpadinking",
                :short_name => "",
                :tag_string => "some tags",
                :request_email => 'edited@localhost',
                :last_edit_comment => 'From test code',
                :translations_attributes => {
                    # Update existing translation
                    'es' => { :locale => "es",
                              :name => "Renamed Department for Humpadinking",
                              :short_name => "",
                              :request_email => 'edited@localhost' },
                    # Add new translation
                    'fr' => { :locale => "fr",
                              :name => "Le Department for Humpadinking",
                              :short_name => "",
                              :request_email => 'edited@localhost' }
                }
            }
        }

        request.flash[:notice].should include('successful')

        pb = PublicBody.find(public_bodies(:humpadink_public_body).id)

        I18n.with_locale(:es) do
           expect(pb.name).to eq('Renamed Department for Humpadinking')
        end

        I18n.with_locale(:fr) do
           expect(pb.name).to eq('Le Department for Humpadinking')
        end

    end

    it "saves edits to a public body in another locale" do
        I18n.with_locale(:es) do
            pb = PublicBody.find(id=3)
            pb.name.should == "El Department for Humpadinking"
            post :update, {
                :id => 3,
                :public_body => {
                    :name => "Department for Humpadinking",
                    :short_name => "",
                    :tag_string => "some tags",
                    :request_email => 'edited@localhost',
                    :last_edit_comment => 'From test code',
                    :translations_attributes => {
                        'es' => { :locale => "es",
                                  :name => "Renamed",
                                  :short_name => "",
                                  :request_email => 'edited@localhost' }
                        }
                    }
                }
            request.flash[:notice].should include('successful')
        end

        pb = PublicBody.find(public_bodies(:humpadink_public_body).id)

        I18n.with_locale(:es) do
           expect(pb.name).to eq('Renamed')
        end

        I18n.with_locale(:en) do
           expect(pb.name).to eq('Department for Humpadinking')
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
        response.should redirect_to(:controller=>'admin_public_body', :action=>'list')
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
        response.should redirect_to(:action=>'list')
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
        config = MySociety::Config.load_default()
        config['SKIP_ADMIN_AUTH'] = false
        basic_auth_login @request
    end
    after do
        config = MySociety::Config.load_default()
        config['SKIP_ADMIN_AUTH'] = true
    end

    def setup_emergency_credentials(username, password)
        config = MySociety::Config.load_default()
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
        config = MySociety::Config.load_default()
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
            config = MySociety::Config.load_default()
            config['SKIP_ADMIN_AUTH'] = true
            @request.env["HTTP_AUTHORIZATION"] = ""
            @request.env["REMOTE_USER"] = "i_am_admin"
            post :show, { :id => public_bodies(:humpadink_public_body).id }
            controller.send(:admin_current_user).should == "i_am_admin"
        end

    end
end


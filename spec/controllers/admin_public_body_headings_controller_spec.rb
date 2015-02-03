require 'spec_helper'

describe AdminPublicBodyHeadingsController do

    context 'when showing the form for a new public body category' do
        it 'should assign a new public body heading to the view' do
            get :new
            assigns[:heading].should be_a(PublicBodyHeading)
        end

        it "builds new translations for all locales" do
            get :new

            translations = assigns[:heading].translations.map{ |t| t.locale.to_s }.sort
            available = I18n.available_locales.map{ |l| l.to_s }.sort

            expect(translations).to eq(available)
        end

        it 'renders the new template' do
            get :new
            expect(response).to render_template('new')
        end
    end

    context 'when creating a public body heading' do
        it "creates a new public body heading in one locale" do
            n = PublicBodyHeading.count
            post :create, {
                :public_body_heading => {
                    :name => 'New Heading'
                 }
            }
            PublicBodyHeading.count.should == n + 1

            heading = PublicBodyHeading.find_by_name("New Heading")
            response.should redirect_to(admin_categories_path)
        end

        it 'creates a new public body heading with multiple locales' do
            n = PublicBodyHeading.count
            post :create, {
                :public_body_heading => {
                    :name => 'New Heading',
                    :translations_attributes => {
                      'es' => { :locale => "es",
                                :name => "Mi Nuevo Heading" }
                    }
                }
            }
            PublicBodyHeading.count.should == n + 1

            heading = PublicBodyHeading.find_by_name("New Heading")
            heading.translations.map {|t| t.locale.to_s}.sort.should == ["en", "es"]
            I18n.with_locale(:en) do
                heading.name.should == "New Heading"
            end
            I18n.with_locale(:es) do
                heading.name.should == "Mi Nuevo Heading"
            end

            response.should redirect_to(admin_categories_path)
        end

        it "renders the form if creating the record was unsuccessful" do
            post :create, :public_body_heading => { :name => '' }
            expect(response).to render_template('new')
        end

    end

    context 'when editing a public body heading' do
        before do
            @heading = FactoryGirl.create(:public_body_heading)
        end

        render_views

        it "finds the requested heading" do
            get :edit, :id => @heading.id
            expect(assigns[:heading]).to eq(@heading)
        end

        it "builds new translations if the body does not already have a translation in the specified locale" do
            get :edit, :id => @heading.id
            expect(assigns[:heading].translations.map(&:locale)).to include(:fr)
        end

        it "renders the edit template" do
            get :edit, :id => @heading.id
            expect(assigns[:heading]).to render_template('edit')
        end
    end

    context 'when updating a public body heading' do
        before do
            @heading = FactoryGirl.create(:public_body_heading)
            @name = @heading.name
        end

        it "saves edits to a public body heading" do
            post :update, { :id => @heading.id,
                            :public_body_heading => { :name => "Renamed" } }
            request.flash[:notice].should include('successful')
            found_heading = PublicBodyHeading.find(@heading.id)
            found_heading.name.should == "Renamed"
        end

        it "saves edits to a public body heading in another locale" do
            I18n.with_locale(:es) do
                post :update, {
                    :id => @heading.id,
                    :public_body_heading => {
                        :name => @name,
                        :translations_attributes => {
                            'es' => { :locale => "es",
                                      :name => "Renamed" }
                            }
                        }
                    }
                request.flash[:notice].should include('successful')
            end

            heading = PublicBodyHeading.find(@heading.id)
            I18n.with_locale(:es) do
               heading.name.should == "Renamed"
            end
            I18n.with_locale(:en) do
               heading.name.should == @name
            end
        end

        it 'adds a new translation' do
             put :update, {
                 :id => @heading.id,
                 :public_body_heading => {
                     :name => @heading.name,
                     :translations_attributes => {
                         'es' => { :locale => "es",
                                   :name => "Example Public Body Heading ES"}
                     }
                 }
             }

             request.flash[:notice].should include('successful')

             pbh = PublicBodyHeading.find(@heading.id)

             I18n.with_locale(:es) do
                expect(pbh.name).to eq('Example Public Body Heading ES')
             end
         end

        it 'adds new translations' do
            post :update, {
                :id => @heading.id,
                :public_body_heading => {
                    :name => @heading.name,
                    :translations_attributes => {
                        'es' => { :locale => "es",
                                  :name => "Example Public Body Heading ES" },
                        'fr' => { :locale => "fr",
                                  :name => "Example Public Body Heading FR" },
                    }
                }
            }

            request.flash[:notice].should include('successful')

            pbh = PublicBodyHeading.find(@heading.id)

            I18n.with_locale(:es) do
               expect(pbh.name).to eq('Example Public Body Heading ES')
            end
            I18n.with_locale(:fr) do
               expect(pbh.name).to eq('Example Public Body Heading FR')
            end
        end

        it 'updates an existing translation and adds a third translation' do
            @heading.translations.create(:locale => 'es',
                                         :name => 'Example Public Body Heading ES')
            @heading.reload

            post :update, {
                :id => @heading.id,
                :public_body_heading => {
                    :name => @heading.name,
                    :translations_attributes => {
                        # Update existing translation
                        'es' => { :locale => "es",
                                  :name => "Renamed Example Public Body Heading ES" },
                        # Add new translation
                        'fr' => { :locale => "fr",
                                  :name => "Example Public Body Heading FR" }
                    }
                }
            }

            request.flash[:notice].should include('successful')

            pbh = PublicBodyHeading.find(@heading.id)

            I18n.with_locale(:es) do
               expect(pbh.name).to eq('Renamed Example Public Body Heading ES')
            end
            I18n.with_locale(:fr) do
               expect(pbh.name).to eq('Example Public Body Heading FR')
            end
        end

        it "redirects to the edit page after a successful update" do
            post :update, { :id => @heading.id,
                            :public_body_heading => { :name => "Renamed" } }

            expect(response).to redirect_to(edit_admin_heading_path(@heading))
        end

        it "re-renders the edit form after an unsuccessful update" do
            post :update, { :id => @heading.id,
                            :public_body_heading => { :name => '' } }

            expect(response).to render_template('edit')
        end

    end

    context 'when destroying a public body heading' do

        before do
            @heading = FactoryGirl.create(:public_body_heading)
        end

        it "destroys a public body heading that has associated categories" do
            category = FactoryGirl.create(:public_body_category)
            link = FactoryGirl.create(:public_body_category_link,
                                      :public_body_category => category,
                                      :public_body_heading => @heading,
                                      :category_display_order => 0)
            n = PublicBodyHeading.count
            n_links = PublicBodyCategoryLink.count

            post :destroy, { :id => @heading.id }
            response.should redirect_to(admin_categories_path)
            PublicBodyHeading.count.should == n - 1
            PublicBodyCategoryLink.count.should == n_links - 1
        end

        it "destroys an empty public body heading" do
            n = PublicBodyHeading.count
            post :destroy, { :id => @heading.id }
            response.should redirect_to(admin_categories_path)
            PublicBodyHeading.count.should == n - 1
        end
    end

    context 'when reordering public body headings' do

        render_views

        before do
            @first = FactoryGirl.create(:public_body_heading, :display_order => 0)
            @second = FactoryGirl.create(:public_body_heading, :display_order => 1)
            @default_params = { :headings => [@second.id, @first.id] }
        end

        def make_request(params=@default_params)
            post :reorder, params
        end

        context 'when handling valid input' do

            it 'should reorder headings according to their position in the submitted params' do
                make_request
                PublicBodyHeading.find(@second.id).display_order.should == 0
                PublicBodyHeading.find(@first.id).display_order.should == 1
            end

            it 'should return a "success" status' do
                make_request
                response.should be_success
            end
        end

        context 'when handling invalid input' do

            before do
                @params = { :headings => [@second.id, @first.id, @second.id + 1]}
            end

            it 'should return an "unprocessable entity" status and an error message' do
                make_request(@params)
                assert_response :unprocessable_entity
                response.body.should match("Couldn't find PublicBodyHeading with id")
            end

            it 'should not reorder headings' do
                make_request(@params)
                PublicBodyHeading.find(@first.id).display_order.should == 0
                PublicBodyHeading.find(@second.id).display_order.should == 1
            end

        end
    end

    context 'when reordering public body categories' do

        render_views

        before do
            @heading = FactoryGirl.create(:public_body_heading)
            @first_category = FactoryGirl.create(:public_body_category)
            @first_link = FactoryGirl.create(:public_body_category_link,
                                             :public_body_category => @first_category,
                                             :public_body_heading => @heading,
                                             :category_display_order => 0)
            @second_category = FactoryGirl.create(:public_body_category)
            @second_link = FactoryGirl.create(:public_body_category_link,
                                                  :public_body_category => @second_category,
                                                  :public_body_heading => @heading,
                                                  :category_display_order => 1)
            @default_params = { :categories => [@second_category.id, @first_category.id],
                                :id => @heading }
            @old_order = [@first_category, @second_category]
            @new_order = [@second_category, @first_category]
        end

        def make_request(params=@default_params)
            post :reorder_categories, params
        end

        context 'when handling valid input' do

            it 'should reorder categories for the heading according to their position \
                in the submitted params' do

                @heading.public_body_categories.should == @old_order
                make_request
                @heading.public_body_categories(reload=true).should == @new_order
            end

            it 'should return a success status' do
                make_request
                response.should be_success
            end
        end

        context 'when handling invalid input' do

            before do
                @new_category = FactoryGirl.create(:public_body_category)
                @params = @default_params.merge(:categories => [@second_category.id,
                                                                @first_category.id,
                                                                @new_category.id])
            end

            it 'should return an "unprocessable entity" status and an error message' do
                make_request(@params)
                assert_response :unprocessable_entity
                response.body.should match("Couldn't find PublicBodyCategoryLink")
            end

            it 'should not reorder the categories for the heading' do
                make_request(@params)
                @heading.public_body_categories(reload=true).should == @old_order
            end
        end

    end
end

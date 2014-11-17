require 'spec_helper'

describe AdminPublicBodyHeadingsController do

    context 'when showing the form for a new public body category' do
        it 'should assign a new public body heading to the view' do
            get :new
            assigns[:heading].should be_a(PublicBodyHeading)
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
                    :translated_versions => [{ :locale => "es",
                                               :name => "Mi Nuevo Heading" }]
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
                        :translated_versions => {
                            @heading.id => {:locale => "es",
                                            :name => "Renamed"}
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

        it "redirects to the edit page after a successful update" do
            post :update, { :id => @heading.id,
                            :public_body_heading => { :name => "Renamed" } }

            expect(response).to redirect_to(edit_admin_heading_path(@heading))
        end

    end

    context 'when destroying a public body heading' do

        before do
            @heading = FactoryGirl.create(:public_body_heading)
        end

        it "does not destroy a public body heading that has associated categories" do
            category = FactoryGirl.create(:public_body_category)
            link = FactoryGirl.create(:public_body_category_link,
                                      :public_body_category => category,
                                      :public_body_heading => @heading,
                                      :category_display_order => 0)
            n = PublicBodyHeading.count
            post :destroy, { :id => @heading.id }
            response.should redirect_to(edit_admin_heading_path(@heading))
            PublicBodyHeading.count.should == n
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

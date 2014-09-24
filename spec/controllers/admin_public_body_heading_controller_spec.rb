require 'spec_helper'

describe AdminPublicBodyHeadingController do
    context 'when showing the index of categories and headings' do
        render_views

        it 'redirect to the category list page from the index' do
            get :index
            response.should redirect_to :admin_category_index
        end
    end

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
            response.should redirect_to(:controller=>'admin_public_body_category', :action=>'index')
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

            response.should redirect_to(:controller=>'admin_public_body_category', :action=>'index')
        end
    end

    context 'when editing a public body heading' do
        before do
            @heading = FactoryGirl.create(:public_body_heading)
        end

        render_views

        it "edits a public body heading" do
            get :edit, :id => @heading.id
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
            response.should redirect_to(:controller=>'admin_public_body_heading', :action=>'edit', :id => @heading.id)
            PublicBodyHeading.count.should == n
        end

        it "destroys an empty public body heading" do
            n = PublicBodyHeading.count
            post :destroy, { :id => @heading.id }
            response.should redirect_to(:controller=>'admin_public_body_category', :action=>'index')
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
end

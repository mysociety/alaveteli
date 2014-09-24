require 'spec_helper'

describe AdminPublicBodyCategoryController do
    context 'when showing the index of categories and headings' do
        render_views

        it 'shows the index page' do
            get :index
        end
    end

    context 'when showing the form for a new public body category' do
        it 'should assign a new public body category to the view' do
            get :new
            assigns[:category].should be_a(PublicBodyCategory)
        end
    end

    context 'when creating a public body category' do
        it "creates a new public body category in one locale" do
            n = PublicBodyCategory.count
            post :create, {
                :public_body_category => {
                    :title => 'New Category',
                    :category_tag => 'new_test_category',
                    :description => 'New category for testing stuff'
                 }
            }
            PublicBodyCategory.count.should == n + 1

            category = PublicBodyCategory.find_by_title("New Category")
            response.should redirect_to(:controller=>'admin_public_body_category', :action=>'index')
        end

        it "saves the public body category's heading associations" do
            heading = FactoryGirl.create(:public_body_heading)
            post :create, {
                :public_body_category => {
                    :title => 'New Category',
                    :category_tag => 'new_test_category',
                    :description => 'New category for testing stuff'
                 },
                 :headings => {"heading_#{heading.id}" => heading.id}
            }
            request.flash[:notice].should include('successful')
            category = PublicBodyCategory.find_by_title("New Category")
            category.public_body_headings.should == [heading]
        end


        it 'creates a new public body category with multiple locales' do
            n = PublicBodyCategory.count
            post :create, {
                :public_body_category => {
                    :title => 'New Category',
                    :category_tag => 'new_test_category',
                    :description => 'New category for testing stuff',
                    :translated_versions => [{ :locale => "es",
                                               :title => "Mi Nuevo Category" }]
                }
            }
            PublicBodyCategory.count.should == n + 1

            category = PublicBodyCategory.find_by_title("New Category")
            category.translations.map {|t| t.locale.to_s}.sort.should == ["en", "es"]
            I18n.with_locale(:en) do
                category.title.should == "New Category"
            end
            I18n.with_locale(:es) do
                category.title.should == "Mi Nuevo Category"
            end

            response.should redirect_to(:controller=>'admin_public_body_category', :action=>'index')
        end
    end

    context 'when editing a public body category' do
        before do
            @category = FactoryGirl.create(:public_body_category)
            I18n.with_locale('es') do
                @category.title = 'Los category'
                @category.save!
            end
        end

        render_views

        it "edits a public body category" do
            get :edit, :id => @category.id
        end

        it "edits a public body in another locale" do
            get :edit, {:id => @category.id, :locale => :en}

            # When editing a body, the controller returns all available translations
            assigns[:category].find_translation_by_locale("es").title.should == 'Los category'
            response.should render_template('edit')
        end
    end

    context 'when updating a public body category' do

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
                @category.save!
            end
        end

        render_views

        it "saves edits to a public body category" do
            post :update, { :id => @category.id,
                            :public_body_category => { :title => "Renamed" } }
            request.flash[:notice].should include('successful')
            pbc = PublicBodyCategory.find(@category.id)
            pbc.title.should == "Renamed"
        end

        it "saves edits to a public body category's heading associations" do
            @category.public_body_headings.should == [@heading]
            heading = FactoryGirl.create(:public_body_heading)
            post :update, { :id => @category.id,
                            :public_body_category => { :title => "Renamed" },
                            :headings => {"heading_#{heading.id}" => heading.id} }
            request.flash[:notice].should include('successful')
            pbc = PublicBodyCategory.find(@category.id)
            pbc.public_body_headings.should == [heading]
        end

        it "saves edits to a public body category in another locale" do
            I18n.with_locale(:es) do
                @category.title.should == 'Los category'
                post :update, {
                    :id => @category.id,
                    :public_body_category => {
                        :title => "Category",
                        :translated_versions => {
                            @category.id => {:locale => "es",
                                  :title => "Renamed"}
                            }
                        }
                    }
                request.flash[:notice].should include('successful')
            end

            pbc = PublicBodyCategory.find(@category.id)
            I18n.with_locale(:es) do
               pbc.title.should == "Renamed"
            end
            I18n.with_locale(:en) do
               pbc.title.should == "Category"
            end
        end

        it "does not save edits to category_tag if the category has associated bodies" do
            body = FactoryGirl.create(:public_body, :tag_string => @tag)
            post :update, { :id => @category.id,
                            :public_body_category => { :category_tag => "renamed" } }
            request.flash[:notice].should include('can\'t')
            pbc = PublicBodyCategory.find(@category.id)
            pbc.category_tag.should == @tag
        end


        it "save edits to category_tag if the category has no associated bodies" do
            category = PublicBodyCategory.create(:title => "Empty Category", :category_tag => "empty", :description => "-")
            post :update, { :id => category.id,
                            :public_body_category => { :category_tag => "renamed" } }
            request.flash[:notice].should include('success')
            pbc = PublicBodyCategory.find(category.id)
            pbc.category_tag.should == "renamed"
        end
    end

    context 'when destroying a public body category' do

        it "destroys a public body category" do
            pbc = PublicBodyCategory.create(:title => "Empty Category", :category_tag => "empty", :description => "-")
            n = PublicBodyCategory.count
            post :destroy, { :id => pbc.id }
            response.should redirect_to(:controller=>'admin_public_body_category', :action=>'index')
            PublicBodyCategory.count.should == n - 1
        end
    end

    context 'when reordering public body categories' do

        render_views

        before do
            @silly_heading = FactoryGirl.create(:silly_heading)
            @useless_category = @silly_heading.public_body_categories.detect do |category|
                category.title == 'Useless ministries'
            end
            @lonely_category = @silly_heading.public_body_categories.detect do |category|
                category.title == 'Lonely agencies'
            end
            @default_params = { :categories => [@lonely_category.id, @useless_category.id],
                                :heading_id => @silly_heading }
        end

        def make_request(params=@default_params)
            post :reorder, params
        end

        context 'when handling valid input' do

            it 'should reorder categories for the heading according to their position \
                in the submitted params' do
                old_order = [@useless_category, @lonely_category]
                new_order = [@lonely_category, @useless_category]
                @silly_heading.public_body_categories.should == old_order
                make_request
                @silly_heading.public_body_categories(reload=true).should == new_order
            end

            it 'should return a success status' do
                make_request
                response.should be_success
            end
        end

        context 'when handling invalid input' do

            it 'should return an "unprocessable entity" status and an error message' do
                @lonely_category.destroy
                make_request
                assert_response :unprocessable_entity
                response.body.should match("Couldn't find PublicBodyCategoryLink")
            end

        end

    end

end

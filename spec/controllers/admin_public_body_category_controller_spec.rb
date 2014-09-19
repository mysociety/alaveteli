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
            @category = FactoryGirl.create(:useless_category)
            I18n.with_locale('es') do
                @category.title = 'Los useless ministries'
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
            assigns[:category].find_translation_by_locale("es").title.should == 'Los useless ministries'
            response.should render_template('edit')
        end
    end

    context 'when updating a public body category' do

        before do
            @heading = FactoryGirl.create(:silly_heading)
            @category = @heading.public_body_categories.detect do |category|
                category.title == 'Useless ministries'
            end
            I18n.with_locale('es') do
                @category.title = 'Los useless ministries'
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
            @category.public_body_headings.count.should == 1
            @category.public_body_headings.first.name.should == "Silly ministries"
            heading = FactoryGirl.create(:popular_heading)
            post :update, { :id => @category.id,
                            :public_body_category => { :title => "Renamed" },
                            :headings => {"heading_#{heading.id}" => heading.id} }
            request.flash[:notice].should include('successful')
            pbc = PublicBodyCategory.find(@category.id)
            pbc.public_body_headings.should == [heading]
        end

        it "saves edits to a public body category in another locale" do
            I18n.with_locale(:es) do
                @category.title.should == 'Los useless ministries'
                post :update, {
                    :id => @category.id,
                    :public_body_category => {
                        :title => "Useless ministries",
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
               pbc.title.should == "Useless ministries"
            end
        end

        it "does not save edits to category_tag if the category has associated bodies" do
            post :update, { :id => @category.id,
                            :public_body_category => { :category_tag => "renamed" } }
            request.flash[:notice].should include('can\'t')
            pbc = PublicBodyCategory.find(@category.id)
            pbc.category_tag.should == "useless_agency"
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
end

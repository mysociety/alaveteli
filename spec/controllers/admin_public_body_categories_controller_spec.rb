require 'spec_helper'

describe AdminPublicBodyCategoriesController do
    context 'when showing the index of categories and headings' do
        render_views

        it 'shows the index page' do
            get :index
            expect(response).to be_success
        end
    end

    context 'when showing the form for a new public body category' do
        it 'should assign a new public body category to the view' do
            get :new
            assigns[:category].should be_a(PublicBodyCategory)
        end

        it 'renders the new template' do
            get :new
            expect(response).to render_template('new')
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
            response.should redirect_to(admin_categories_path)
        end

        it "saves the public body category's heading associations" do
            heading = FactoryGirl.create(:public_body_heading)
            category_attributes = FactoryGirl.attributes_for(:public_body_category)
            post :create, {
                    :public_body_category => category_attributes,
                    :headings => {"heading_#{heading.id}" => heading.id}
            }
            request.flash[:notice].should include('successful')
            category = PublicBodyCategory.find_by_title(category_attributes[:title])
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

            response.should redirect_to(admin_categories_path)
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

        it "finds the requested category" do
            get :edit, :id => @category.id
            expect(assigns[:category]).to eq(@category)
        end

        it "renders the edit template" do
            get :edit, :id => @category.id
            expect(assigns[:category]).to render_template('edit')
        end

        it "edits a public body in another locale" do
            get :edit, { :id => @category.id, :locale => :en }

            # When editing a body, the controller returns all available
            # translations
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

        it "redirects to the edit page after a successful update" do
            post :update, { :id => @category.id,
                            :public_body_category => { :title => "Renamed" } }

            expect(response).to redirect_to(edit_admin_category_path(@category))
        end

        it "re-renders the edit form after an unsuccessful update" do
            post :update, { :id => @category.id,
                            :public_body_category => { :title => '' } }

            expect(response).to render_template('edit')
        end

    end

    context 'when destroying a public body category' do

        it "destroys a public body category" do
            pbc = PublicBodyCategory.create(:title => "Empty Category", :category_tag => "empty", :description => "-")
            n = PublicBodyCategory.count
            post :destroy, { :id => pbc.id }
            response.should redirect_to(admin_categories_path)
            PublicBodyCategory.count.should == n - 1
        end
    end


end

# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminHolidaysController do

    describe :index do

        before do
            @holiday_one = FactoryGirl.create(:holiday, :day => Date.new(2010, 1, 1))
            @holiday_two = FactoryGirl.create(:holiday, :day => Date.new(2011, 2, 2))
            @holiday_three = FactoryGirl.create(:holiday, :day => Date.new(2011, 3, 3))
        end

        it 'gets a hash of holidays keyed by year' do
           get :index
           assigns(:holidays_by_year)[2010].should include(@holiday_one)
           assigns(:holidays_by_year)[2011].should include(@holiday_two)
           assigns(:holidays_by_year)[2011].should include(@holiday_three)
        end

        it 'gets a list of years with holidays' do
            get :index
            assigns(:years).should include(2010)
            assigns(:years).should include(2011)
        end

        it 'renders the index template' do
           get :index
           expect(response).to render_template('index')
        end

    end

    describe :new do


        describe 'when not using ajax' do

            it 'renders the new template' do
                get :new
                expect(response).to render_template('new')
            end

        end

        describe 'when using ajax' do

            it 'renders the new form partial' do
                xhr :get, :new
                expect(response).to render_template('new_form')
            end
        end

        it 'creates a new holiday' do
            get :new
            assigns[:holiday].should be_instance_of(Holiday)
        end

    end

    describe :create do

        before do
            @holiday_params = { :description => "New Year's Day",
                                'day(1i)' => '2010',
                                'day(2i)' => '1',
                                'day(3i)' => '1' }
            post :create, :holiday => @holiday_params
        end

        it 'creates a new holiday' do
            assigns(:holiday).description.should == @holiday_params[:description]
            assigns(:holiday).day.should == Date.new(2010, 1, 1)
            assigns(:holiday).should be_persisted
        end

        it 'shows the admin a success message' do
            flash[:notice].should == 'Holiday successfully created.'
        end

        it 'redirects to the index' do
            response.should redirect_to admin_holidays_path
        end

        context 'when there are errors' do

            before do
                Holiday.any_instance.stub(:save).and_return(false)
                post :create, :holiday => @holiday_params
            end

            it 'renders the new template' do
                expect(response).to render_template('new')
            end
        end

    end

    describe :edit do

        before do
            @holiday = FactoryGirl.create(:holiday)
        end

        describe 'when not using ajax' do

            it 'renders the edit template' do
                get :edit, :id => @holiday.id
                expect(response).to render_template('edit')
            end

        end

        describe 'when using ajax' do

            it 'renders the edit form partial' do
                xhr :get, :edit, :id => @holiday.id
                expect(response).to render_template('edit_form')
            end

        end

        it 'gets the holiday in the id param' do
            get :edit, :id => @holiday.id
            assigns[:holiday].should == @holiday
        end

    end

    describe :update do

        before do
            @holiday = FactoryGirl.create(:holiday, :day => Date.new(2010, 1, 1),
                                                    :description => "Test Holiday")
            put :update, :id => @holiday.id, :holiday => { :description => 'New Test Holiday' }
        end

        it 'gets the holiday in the id param' do
            assigns[:holiday].should == @holiday
        end

        it 'updates the holiday' do
            holiday = Holiday.find(@holiday.id).description.should == 'New Test Holiday'
        end

        it 'shows the admin a success message' do
            flash[:notice].should == 'Holiday successfully updated.'
        end

        it 'redirects to the index' do
            response.should redirect_to admin_holidays_path
        end

        context 'when there are errors' do

            before do
                Holiday.any_instance.stub(:update_attributes).and_return(false)
                put :update, :id => @holiday.id, :holiday => { :description => 'New Test Holiday' }
            end

            it 'renders the edit template' do
                expect(response).to render_template('edit')
            end
        end

    end

    describe :destroy do

        before(:each) do
             @holiday = FactoryGirl.create(:holiday)
             delete :destroy, :id => @holiday.id
         end

         it 'finds the holiday to destroy' do
             assigns(:holiday).should == @holiday
         end

         it 'destroys the holiday' do
             assigns(:holiday).should be_destroyed
         end

         it 'tells the admin the holiday has been destroyed' do
             msg = "Holiday successfully destroyed"
             flash[:notice].should == msg
         end

         it 'redirects to the index action' do
             expect(response).to redirect_to(admin_holidays_path)
         end
    end

 end

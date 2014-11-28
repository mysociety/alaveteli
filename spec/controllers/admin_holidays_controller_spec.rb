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

    describe :edit do

        before do
            @holiday = FactoryGirl.create(:holiday)
        end

        it 'renders the edit template' do
            get :edit, :id => @holiday.id
            expect(response).to render_template('edit')
        end

        it 'gets the holiday in the id param' do
            get :edit, :id => @holiday.id
            assigns[:holiday].should == @holiday
        end


    end

 end

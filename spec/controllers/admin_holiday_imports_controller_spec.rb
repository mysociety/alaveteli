# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminHolidayImportsController do

    describe :new do

        it 'renders the new template' do
            get :new
            expect(response).to render_template('new')
        end

        it 'creates an import' do
            get :new
            assigns[:holiday_import].should be_instance_of(HolidayImport)
        end

        describe 'if the import is valid' do

            it 'populates the import' do
                mock_import = mock(HolidayImport, :valid? => true,
                                                  :populate => nil)
                HolidayImport.stub!(:new).and_return(mock_import)
                mock_import.should_receive(:populate)
                get :new
            end

        end

    end

    describe :create do

        it 'creates an import' do
            post :create
            assigns[:holiday_import].should be_instance_of(HolidayImport)
        end

        describe 'if the import can be saved' do

            before do
                mock_import = mock(HolidayImport, :save => true)
                HolidayImport.stub!(:new).and_return(mock_import)
                post :create
            end

            it 'should show a success notice' do
                flash[:notice].should == 'Holidays successfully imported'
            end

            it 'should redirect to the index' do
                response.should redirect_to(admin_holidays_path)
            end

        end

        describe 'if the import cannot be saved' do

            before do
                mock_import = mock(HolidayImport, :save => false)
                HolidayImport.stub!(:new).and_return(mock_import)
                post :create
            end

            it 'should render the new template' do
                expect(response).to render_template('new')
            end

        end

    end


end

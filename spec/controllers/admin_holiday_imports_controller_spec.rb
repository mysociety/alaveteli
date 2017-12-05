# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminHolidayImportsController do

  describe 'GET new' do

    it 'renders the new template' do
      get :new
      expect(response).to render_template('new')
    end

    it 'creates an import' do
      get :new
      expect(assigns[:holiday_import]).to be_instance_of(HolidayImport)
    end

    describe 'if the import is valid' do

      it 'populates the import' do
        mock_import = double(HolidayImport, :valid? => true,
                           :populate => nil)
        allow(HolidayImport).to receive(:new).and_return(mock_import)
        expect(mock_import).to receive(:populate)
        get :new
      end

    end

  end

  describe 'POST create' do

    it 'creates an import' do
      post :create
      expect(assigns[:holiday_import]).to be_instance_of(HolidayImport)
    end

    describe 'when handling an iCal feed' do

      let(:params) do
        {
          "holiday_import" => {
            "holidays_attributes" => {
              "0" => {
                "description" => "M L King Day",
                "day(1i)" => "2017",
                "day(2i)" => "1",
                "day(3i)" => "16"
              },
              "1" => {
                "description" => "Thanksgiving Day",
                "day(1i)" => "2017",
                "day(2i)" => "11",
                "day(3i)" => "23"
              }
            }
          },
          "commit" => "Import"
        }
      end

      it 'should create the expected holidays' do
        Holiday.delete_all
        post :create, params
        expect(Holiday.count).to eq(2)
      end

    end

    describe 'if the import can be saved' do

      before do
        mock_import = double(HolidayImport, :save => true)
        allow(HolidayImport).to receive(:new).and_return(mock_import)
        post :create
      end

      it 'should show a success notice' do
        expect(flash[:notice]).to eq('Holidays successfully imported')
      end

      it 'should redirect to the index' do
        expect(response).to redirect_to(admin_holidays_path)
      end

    end

    describe 'if the import cannot be saved' do

      before do
        mock_import = double(HolidayImport, :save => false)
        allow(HolidayImport).to receive(:new).and_return(mock_import)
        post :create
      end

      it 'should render the new template' do
        expect(response).to render_template('new')
      end

    end

  end


end

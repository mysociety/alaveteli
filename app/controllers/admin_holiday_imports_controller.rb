# -*- encoding : utf-8 -*-
class AdminHolidayImportsController < AdminController

    def new
        @holiday_import = HolidayImport.new(holiday_import_params)
        @holiday_import.populate if @holiday_import.valid?
    end

    def create
        @holiday_import = HolidayImport.new(holiday_import_params)
        if @holiday_import.save
            redirect_to admin_holidays_path, :notice => 'Holidays successfully imported'
        else
            render :new
        end
    end

    private

    def holiday_import_params
        if params[:holiday_import]
            params[:holiday_import].slice(:holidays_attributes, :start_year, :end_year, :source, :ical_feed_url)
        else
            {}
        end
    end

end

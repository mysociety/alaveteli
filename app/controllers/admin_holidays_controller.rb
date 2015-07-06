# -*- encoding : utf-8 -*-
class AdminHolidaysController < AdminController

    def index
        get_all_holidays
    end

    def new
        @holiday = Holiday.new
        if request.xhr?
            render :partial => 'new_form', :locals => { :holiday => @holiday }
        else
            render :action => 'new'
        end
    end

    def create
        @holiday = Holiday.new(holiday_params)
        if @holiday.save
            notice = "Holiday successfully created."
            redirect_to admin_holidays_path, :notice => notice
        else
            render :new
        end
    end

    def edit
        @holiday = Holiday.find(params[:id])
        if request.xhr?
            render :partial => 'edit_form'
        else
            render :action => 'edit'
        end
    end

    def update
        @holiday = Holiday.find(params[:id])
        if @holiday.update_attributes(holiday_params)
            flash[:notice] = 'Holiday successfully updated.'
            redirect_to admin_holidays_path
        else
            render :edit
        end
    end

    def destroy
        @holiday = Holiday.find(params[:id])
        @holiday.destroy
        notice = "Holiday successfully destroyed"
        redirect_to admin_holidays_path, :notice => notice
    end

    private

    def get_all_holidays
        @holidays_by_year = Holiday.all.group_by { |holiday| holiday.day.year }
        @years = @holidays_by_year.keys.sort.reverse
    end

    def holiday_params(key = :holiday)
        if params[key]
            params[key].slice(:description, 'day(1i)', 'day(2i)', 'day(3i)')
        else
            {}
        end
    end

end

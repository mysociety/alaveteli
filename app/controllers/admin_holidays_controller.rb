class AdminHolidaysController < AdminController

    def index
        get_all_holidays
    end


    def edit
        @holiday = Holiday.find(params[:id])
    end

    private

    def get_all_holidays
        @holidays_by_year = Holiday.all.group_by { |holiday| holiday.day.year }
        @years = @holidays_by_year.keys.sort.reverse
    end

end

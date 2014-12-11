class HolidayImport

    include ActiveModel::Validations

    validate :all_holidays_valid
    validates_inclusion_of :source, :in => %w( suggestions feed )
    validates_presence_of :ical_feed_url,
                :if => proc { |holiday_import| holiday_import.source == 'feed' }
    attr_accessor :holidays,
                  :ical_feed_url,
                  :start_year,
                  :end_year,
                  :start_date,
                  :end_date,
                  :source,
                  :populated


    def initialize(opts = {})
        @populated = false
        @start_year = opts.fetch(:start_year, Time.now.year).to_i
        @end_year = opts.fetch(:end_year, Time.now.year).to_i
        @start_date = Date.civil(start_year, 1, 1)
        @end_date = Date.civil(end_year, 12, 31)
        @source = opts.fetch(:source, 'suggestions')
        @ical_feed_url = opts.fetch(:ical_feed_url, nil)
        self.holidays_attributes = opts.fetch(:holidays_attributes, [])
    end

    def populate
        source == 'suggestions' ? populate_suggestions : populate_from_feed
        @populated = true
    end

    def populate_from_feed
        cal_file = open(ical_feed_url)
        # Parser returns an array of calendars because a single file
        # can have multiple calendars.
        begin
            cals = Icalendar.parse(cal_file, strict=false)
            cal = cals.first
            cal.events.each do |cal_event|
                if cal_event.dtstart > start_date and cal_event.dtstart < end_date
                    holidays << Holiday.new(:description => cal_event.summary,
                                            :day => cal_event.dtstart)
                end
            end
        rescue Exception => e
            if e.message == 'Invalid line in calendar string!'
                errors.add(:ical_feed_url, "Sorry, there's a problem with the format of that feed.")
            else
                raise e
            end
        end
    end


    def populate_suggestions
        @country_code = AlaveteliConfiguration::iso_country_code.downcase
        holiday_info = Holidays.between(start_date, end_date, @country_code.to_sym, :observed)
        holiday_info.each do |holiday_info_hash|
            holidays << Holiday.new(:description => holiday_info_hash[:name],
                                    :day => holiday_info_hash[:date])
        end
    end

    def suggestions_country_name
        IsoCountryCodes.find(@country_code).name if @country_code
    end

    def period
        start_year == end_year ? start_year : "#{start_year}-#{end_year}"
    end

    def all_holidays_valid
        errors.add(:base, 'These holidays could not be imported') unless holidays.all?(&:valid?)
    end

    def save
        holidays.all?(&:save)
    end

    def holidays_attributes=(incoming_data)
        incoming_data.each{ |offset, incoming| self.holidays << Holiday.new(incoming) }
    end

    def holidays
        @holidays ||= []
    end
end

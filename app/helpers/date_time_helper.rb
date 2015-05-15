# -*- encoding : utf-8 -*-
module DateTimeHelper
    # Public: Usually-correct format for a DateTime-ish object
    # To define a new new format define the `simple_date_{FORMAT}` method
    #
    # date - a DateTime, Date or Time
    # opts - a Hash of options (default: { format: :html})
    #        :format - :html returns a HTML <time> tag
    #                  :text returns a plain String
    #
    # Examples
    #
    #   simple_date(Time.now)
    #   # => "<time>..."
    #
    #   simple_date(Time.now, :format => :text)
    #   # => "March 10, 2014"
    #
    # Returns a String
    # Raises ArgumentError if the format is unrecognized
    def simple_date(date, opts = {})
        opts = { :format => :html }.merge(opts)
        date_formatter = "simple_date_#{ opts[:format] }"

        if respond_to?(date_formatter)
            send(date_formatter, date)
        else
            raise ArgumentError, "Unrecognized format :#{ opts[:format] }"
        end
    end

    # Usually-correct HTML formatting of a DateTime-ish object
    # Use LinkToHelper#simple_date with desired formatting options
    #
    # date - a DateTime, Date or Time
    #
    # Returns a String
    def simple_date_html(date)
        date = date.in_time_zone unless date.is_a?(Date)
        time_tag date, simple_date_text(date), :title => date.to_s
    end

    # Usually-correct plain text formatting of a DateTime-ish object
    # Use LinkToHelper#simple_date with desired formatting options
    #
    # date - a DateTime, Date or Time
    #
    # Returns a String
    def simple_date_text(date)
        date = date.in_time_zone.to_date unless date.is_a? Date

        date_format = _('simple_date_format')
        date_format = :long if date_format == 'simple_date_format'
        I18n.l(date, :format => date_format)
    end

    # Strips the date from a DateTime
    #
    # date - a DateTime, Date or Time
    #
    # Examples
    #
    #   simple_time(Time.now)
    #   # => "10:46:54"
    #
    # Returns a String
    def simple_time(date)
        date.strftime("%H:%M:%S").strip
    end
end

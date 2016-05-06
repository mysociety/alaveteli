# -*- encoding : utf-8 -*-
module AnalyticsHelper

  # helpers for embedding Google Analytics code
  #
  # Event categories and actions should be drawn from the list in the
  # lib/analytics_events.rb file (add your own there when making new ones)


  # Public: Constructs a String consisting of a Google Analytics (GA) tracking
  # event function call with the (mandatory) event category and action params
  # and optional label and value params.
  #
  # event_category - The String to be sent to GA as the tracking event category.
  #                  Ideally this should be an AnalyticsEvent::Category::THING
  #                  to avoid having magic strings everywhere
  # event_action   - The String to be sent to GA as the tracking event action.
  #                  Ideally this should be an AnalyticsEvent::Action::THING
  #                  to avoid having magic strings everywhere
  # options        - Hash of optional values, expects:
  #                   label           - String, an optional label for the event
  #                   label_is_script - Boolean, whether to treat the label
  #                                     String as literal or browser-
  #                                     interpreted (Javascript)
  #                   value           - Integer, Google insists that a numerical
  #                                     value param is supplied if label is used;
  #                                     if you don't care about this value and
  #                                     don't want to set it, leave it blank
  #                                     and a default of 1 will be sent
  #                  Any other supplied options will be ignored
  #
  # Examples
  #
  #   track_analytics_event("test", "button clicked")
  #   # => "if (ga) { ga('send','event','test','button clicked') };"
  #
  #   track_analytics_event("test", "vote button", :label => "sidebar")
  #   # => "if (ga) { ga('send','event','test','vote button','sidebar',1) };"
  #
  #   track_analytics_event("test", "Points Scored", :label => "Bonus", :value => 100)
  #   # => "if (ga) { ga('send','event','test','Points Scored','Bonus',100) };"
  #
  #   track_analytics_event("test",
  #                         "Embedded",
  #                         :label => "window.location.href",
  #                         :label_is_script => true)
  #   # => "if (ga) { ga('send','event','test','Embedded',window.location.href,1) };"
  #
  # Returns a string of a GA JavaScript function to drop into an :onclick handler
  def track_analytics_event(event_category, event_action, options={})
    begin
      value = if options[:value].nil?
        1
      else
        Integer(options[:value])
      end
    rescue ArgumentError
      raise ArgumentError, %Q(:value option must be an Integer: "#{ options[:value] }")
    end

    label_is_script = options[:label_is_script] == true
    label = options[:label]
    if label
      label_string = ",#{format_event_label(label, label_is_script)},#{value}"
    end
    event_args = "'#{event_category}','#{event_action}'#{label_string}"
    "if (ga) { ga('send','event',#{event_args}) };"
  end

  private

  # Private: Format the event label by wrapping in single quotes if it is
  # going to be used as a String literal (e.g. "'Button clicked'") or without if
  # it is a JavaScript string (e.g. "window.location.href") that needs to be run
  # and interpreted by the browser.
  #
  # label     - The label text (String) to by used
  # is_script - Boolean indicating whether the supplied label text is intended
  #             to be interpreted as JavaScript by the browser (defaults
  #             to false)
  #
  # Examples
  #
  #   format_event_label("Vote Button Clicked", false)
  #   # => "'Vote Button Clicked'"
  #
  #   format_event_label("window.top.location.href", true)
  #   # => "window.top.location.href"
  #
  # Returns the label String with or without containing single quotes,
  # depending on the value of the is_script param default behaviour:
  #   is_script is evaluated as false, string returned wrapped in single quotes)
  def format_event_label(label, is_script=false)
    if is_script
      label
    else
      "'#{label}'"
    end
  end

end

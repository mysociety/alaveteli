# -*- encoding : utf-8 -*-
module InfoRequestCustomStates
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Mixin methods for InfoRequest
  def theme_calculate_status
    return 'waiting_classification' if awaiting_description
    waiting_response = described_state == "waiting_response" || described_state == "deadline_extended"
    return described_state unless waiting_response
    if described_state == 'deadline_extended'
      return 'deadline_extended' if
      Time.zone.now.strftime("%Y-%m-%d") < date_deadline_extended.strftime("%Y-%m-%d")
      return 'waiting_response_very_overdue'  if
      Time.zone.now.strftime("%Y-%m-%d") > Holiday.due_date_from_working_days(date_deadline_extended, 15).strftime("%Y-%m-%d")
      return 'waiting_response_overdue'
    end
    return 'waiting_response_very_overdue' if
    Time.zone.now.strftime("%Y-%m-%d") > date_very_overdue_after.strftime("%Y-%m-%d")
    return 'waiting_response_overdue' if
    Time.zone.now.strftime("%Y-%m-%d") > date_response_required_by.strftime("%Y-%m-%d")
    'waiting_response'
  end

  def date_deadline_extended
    # TODO: shouldn't this be 15 days after the date the status was
    # changed to "deadline extended"? Or perhaps 15 days ater the
    # initial request due date?
    Holiday.due_date_from_working_days(date_response_required_by, 15)
  end

  module ClassMethods
    def theme_display_status(status)
      if status == 'deadline_extended'
        _("Deadline extended.")
      elsif status == 'wrong_response'
        _("Wrong Response.")
      else
        raise _("unknown status {{status}}", status: status)
      end
    end

    def theme_short_description(status)
      if status == 'deadline_extended'
        _("Deadline extended")
      elsif status == 'wrong_response'
        _("Wrong Response")
      else
        raise _("unknown status {{status}}", status: status)
      end
    end

    def theme_extra_states
      %w[deadline_extended
         wrong_response]
    end
  end
end

module RequestControllerCustomStates
  def theme_describe_state(info_request)
    # called after the core describe_state code.  It should
    # end by raising an error if the status is unknown
    if info_request.calculate_status == 'deadline_extended'
      flash[:notice] = _("Authority has requested extension of the deadline.")
      redirect_to unhappy_url(info_request)
    elsif info_request.calculate_status == 'wrong_response'
      flash[:notice] = _("Oh no! Sorry to hear that your request was wrong. Here is what to do now.")
      redirect_to unhappy_url(info_request)
    else
      raise "unknown calculate_status " + info_request.calculate_status
    end
  end
end

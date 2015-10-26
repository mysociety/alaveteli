# -*- encoding : utf-8 -*-
class InfoRequestThemeStates

  # Mixin methods for InfoRequest
  def calculate_status(info_request)
    return 'waiting_classification' if info_request.awaiting_description
    waiting_response = info_request.described_state == "waiting_response" || info_request.described_state == "deadline_extended"
    return info_request.described_state unless waiting_response
    if info_request.described_state == 'deadline_extended'
      return 'deadline_extended' if
      Time.now.strftime("%Y-%m-%d") < date_deadline_extended(info_request).strftime("%Y-%m-%d")
      return 'waiting_response_very_overdue'  if
      Time.now.strftime("%Y-%m-%d") > Holiday.due_date_from_working_days(date_deadline_extended(info_request), 15).strftime("%Y-%m-%d")
      return 'waiting_response_overdue'
    end
    return 'waiting_response_very_overdue' if
    Time.now.strftime("%Y-%m-%d") > info_request.date_very_overdue_after.strftime("%Y-%m-%d")
    return 'waiting_response_overdue' if
    Time.now.strftime("%Y-%m-%d") > info_request.date_response_required_by.strftime("%Y-%m-%d")
    return 'waiting_response'
  end

  def date_deadline_extended(info_request)
    # TODO: shouldn't this be 15 days after the date the status was
    # changed to "deadline extended"? Or perhaps 15 days ater the
    # initial request due date?
    return Holiday.due_date_from_working_days(info_request.date_response_required_by, 15)
  end

  def display_status(status)
    if status == 'deadline_extended'
      _("Deadline extended.")
    elsif status == 'wrong_response'
      _("Wrong Response.")
    else
      raise _("unknown status ") + status
    end
  end

  def extra_states
    return ['deadline_extended',
            'wrong_response']
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

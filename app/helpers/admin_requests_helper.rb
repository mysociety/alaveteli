# -*- encoding : utf-8 -*-
# Helpers for managing InfoRequests in the admin interface.
module AdminRequestsHelper
  # Public: A radio button for choosing a pre-populated explanation for hiding
  # a user's request.
  #
  # Separate `message` and `state` arguments allow us to use varied messages
  # depending on the particular offence committed by the user.
  #
  # :label - The humanised label to display next to the radio button
  # :state - The state to move the request to after hiding the request
  # :message - The message partial to render (from
  #            `app/views/admin_request/hidden_user_explanation` for the
  #            message to the user
  #
  # Examples
  #
  #   <%= hidden_user_explanation_reason label: 'A vexatious request',
  #                                      state: 'vexatious',
  #                                      message: 'vexatious' %>
  #   # => <label class="radio inline">
  #   # =>   <input type="radio"
  #   # =>          name="reason"
  #   # =>          id="reason_vexatious"
  #   # =>          value="vexatious"
  #   # =>          data-message="vexatious" />
  #   # =>   A vexatious request
  #   # => </label>
  #
  # Returns a String
  # FIXME: Remove default arguments when Ruby 2.1 is the lowest supported Ruby
  def hidden_user_explanation(label: nil, state: nil, message: nil)
    unless InfoRequest::State.all.include?(state)
      raise ArgumentError, "Invalid InfoRequest::State '#{ state }'"
    end

    content_tag :label, class: 'radio inline' do
      id = "reason_#{ state }_#{ message }"
      html_opts = { id: id, data: { message: message } }
      radio_button_tag('reason', state, false, html_opts) + label
    end
  end
end

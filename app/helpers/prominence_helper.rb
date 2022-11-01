##
# Methods to render consistently object's prominence and prominence_reason
# depending on the context (prominence value, current user, format)
#
module ProminenceHelper
  def conceled_prominence?(prominenceable)
    %w{hidden requester_only}.include?(prominenceable.prominence)
  end

  def render_prominence(prominenceable, format: :html)
    return unless conceled_prominence?(prominenceable)

    klass = prominenceable.class::Prominence::Helper
    prominence = klass.new(self, prominenceable)

    return prominence.notice + "\n" * 2 if format == :text

    [prominence.notice, prominence.sign_in, prominence.contact_us].
      join(' ').squish.html_safe
  end

  class Base # :nodoc:
    attr_reader :prominenceable

    delegate :current_user, :request, :link_to,
             :help_contact_path, :signin_path, to: :@helper

    def self.default_prominence_reason
      _("There are various reasons why we might have done this, sorry we " \
        "can't be more specific here.")
    end

    def initialize(helper, prominenceable)
      @helper = helper
      @prominenceable = prominenceable
    end

    def user
      raise NotImplementedError
    end

    def notice
      @notice ||= (
        case prominenceable.prominence
        when 'hidden'
          hidden_notice
        when 'requester_only'
          requester_only_notice
        else
          raise NotImplementedError
        end
      )
    end

    def contact_us
      return if current_user&.is_admin?
      contact_us_notice(
        contact_us_link: link_to(_('contact us'), help_contact_path)
      )
    end

    def sign_in
      return if prominenceable.prominence != 'requester_only'
      return if current_user && current_user == user
      return if current_user&.is_admin?

      sign_in_notice(
        sign_in_link: link_to(_('sign in'), signin_path(r: request.fullpath))
      )
    end

    private

    def hidden_notice
      raise NotImplementedError
    end

    def requester_only_notice
      raise NotImplementedError
    end

    def contact_us_notice(*args)
      _('Please {{contact_us_link}} if you have any questions.', *args)
    end

    def sign_in_notice(*args)
      raise NotImplementedError
    end

    def reason
      prominenceable.prominence_reason.presence || default_prominence_reason
    end

    def default_prominence_reason
      return '' if current_user&.is_admin?
      self.class.default_prominence_reason
    end
  end

  class InfoRequest::Prominence::Helper < Base # :nodoc:
    def user
      prominenceable.user
    end

    def hidden_notice
      if current_user&.is_admin?
        _('This request has prominence "hidden". {{reason}} You can only see ' \
          'it because you are logged in as a super user.', reason: reason)
      else
        _('This request has been hidden. {{reason}}', reason: reason)
      end
    end

    def requester_only_notice
      if current_user && current_user == user
        _('This request is hidden, so that only you, the requester, can see ' \
          'it. {{reason}}', reason: reason)
      elsif current_user&.is_admin?
        _('This request has prominence "requester_only". {{reason}} You can ' \
          'only see it because you are logged in as a super user.',
          reason: reason)
      else
        _('This request has been hidden. {{reason}}', reason: reason)
      end
    end

    def sign_in_notice(*args)
      _('If you are the requester, then you may {{sign_in_link}} to view the ' \
        'request.', *args)
    end
  end

  class IncomingMessage::Prominence::Helper < Base # :nodoc:
    def user
      prominenceable.info_request.user
    end

    def hidden_notice
      if current_user&.is_admin?
        _('This message has prominence "hidden". {{reason}} You can only see ' \
          'it because you are logged in as a super user.', reason: reason)
      else
        _('This message has been hidden. {{reason}}', reason: reason)
      end
    end

    def requester_only_notice
      if current_user && current_user == user
        _('This message is hidden, so that only you, the requester, can see ' \
          'it. {{reason}}', reason: reason)
      elsif current_user&.is_admin?
        _('This message has prominence "requester_only". {{reason}} You can ' \
          'only see it because you are logged in as a super user.',
          reason: reason)
      else
        _('This message has been hidden. {{reason}}', reason: reason)
      end
    end

    def sign_in_notice(*args)
      _('If you are the requester, then you may {{sign_in_link}} to view the ' \
        'message.', *args)
    end
  end

  ::OutgoingMessage::Prominence::Helper = IncomingMessage::Prominence::Helper

  class FoiAttachment::Prominence::Helper < Base # :nodoc:
    def user
      prominenceable.incoming_message.info_request.user
    end

    def hidden_notice
      if current_user&.is_admin?
        _('This attachment has prominence "hidden". {{reason}} You can only ' \
          'see it because you are logged in as a super user.', reason: reason)
      else
        _('This attachment has been hidden. {{reason}}', reason: reason)
      end
    end

    def requester_only_notice
      if current_user && current_user == user
        _('This attachment is hidden, so that only you, the requester, can ' \
          'see it. {{reason}}', reason: reason)
      elsif current_user&.is_admin?
        _('This attachment has prominence "requester_only". {{reason}} You ' \
          'can only see it because you are logged in as a super user.',
          reason: reason)
      else
        _('This attachment has been hidden. {{reason}}', reason: reason)
      end
    end

    def sign_in_notice(*args)
      _('If you are the requester, then you may {{sign_in_link}} to view the ' \
        'attachment.', *args)
    end
  end
end

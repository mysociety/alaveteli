# Parse DSN status code to provide a human readable summary message
class FoiAttachment::DeliveryStatusNotification
  # List of DSN codes taken from RFC 3463
  # http://tools.ietf.org/html/rfc3463
  STATUS_TO_MESSAGE = {
    'X.1.0' => 'Other address status',
    'X.1.1' => 'Bad destination mailbox address',
    'X.1.2' => 'Bad destination system address',
    'X.1.3' => 'Bad destination mailbox address syntax',
    'X.1.4' => 'Destination mailbox address ambiguous',
    'X.1.5' => 'Destination mailbox address valid',
    'X.1.6' => 'Mailbox has moved',
    'X.1.7' => 'Bad sender\'s mailbox address syntax',
    'X.1.8' => 'Bad sender\'s system address',
    'X.2.0' => 'Other or undefined mailbox status',
    'X.2.1' => 'Mailbox disabled, not accepting messages',
    'X.2.2' => 'Mailbox full',
    'X.2.3' => 'Message length exceeds administrative limit.',
    'X.2.4' => 'Mailing list expansion problem',
    'X.3.0' => 'Other or undefined mail system status',
    'X.3.1' => 'Mail system full',
    'X.3.2' => 'System not accepting network messages',
    'X.3.3' => 'System not capable of selected features',
    'X.3.4' => 'Message too big for system',
    'X.4.0' => 'Other or undefined network or routing status',
    'X.4.1' => 'No answer from host',
    'X.4.2' => 'Bad connection',
    'X.4.3' => 'Routing server failure',
    'X.4.4' => 'Unable to route',
    'X.4.5' => 'Network congestion',
    'X.4.6' => 'Routing loop detected',
    'X.4.7' => 'Delivery time expired',
    'X.5.0' => 'Other or undefined protocol status',
    'X.5.1' => 'Invalid command',
    'X.5.2' => 'Syntax error',
    'X.5.3' => 'Too many recipients',
    'X.5.4' => 'Invalid command arguments',
    'X.5.5' => 'Wrong protocol version',
    'X.6.0' => 'Other or undefined media error',
    'X.6.1' => 'Media not supported',
    'X.6.2' => 'Conversion required and prohibited',
    'X.6.3' => 'Conversion required but not supported',
    'X.6.4' => 'Conversion with loss performed',
    'X.6.5' => 'Conversion failed',
    'X.7.0' => 'Other or undefined security status',
    'X.7.1' => 'Delivery not authorized, message refused',
    'X.7.2' => 'Mailing list expansion prohibited',
    'X.7.3' => 'Security conversion required but not possible',
    'X.7.4' => 'Security features not supported',
    'X.7.5' => 'Cryptographic failure',
    'X.7.6' => 'Cryptographic algorithm not supported',
    'X.7.7' => 'Message integrity failure'
  }.freeze

  def initialize(body)
    @body = body
  end

  def status
    @status ||= status!
  end

  def message
    STATUS_TO_MESSAGE[status_part]
  end

  private

  attr_reader :body

  def status!
    @status = match ? match[1] : nil
  end

  def status_part
    return '' unless match

    'X.' + match[2]
  end

  def match
    body.match(/Status:\s+([0-9]+\.([0-9]+\.[0-9]+))\s+/)
  end
end

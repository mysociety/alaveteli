require 'spec_helper'

RSpec.describe OneTimePasswordsHelper do
  include OneTimePasswordsHelper

  describe '#otp_provisioning_qr_code' do
    it 'renders an SVG QR code for the given provisioning URI' do
      svg = otp_provisioning_qr_code('otpauth://totp/example')
      expect(svg).to include('<svg')
      expect(svg).to include('</svg>')
    end
  end
end

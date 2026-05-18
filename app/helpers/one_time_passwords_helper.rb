# View helpers for the two factor authentication setup flow.
module OneTimePasswordsHelper
  def otp_provisioning_qr_code(provisioning_uri)
    raw RQRCode::QRCode.new(provisioning_uri).as_svg(
      module_size: 5,
      use_path: true
    )
  end
end

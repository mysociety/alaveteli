{
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
  inherit (config.security.acme) certs;
in
{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
  inherit (config.security.acme) certs;
  dovecotConf = pkgs.writeText "dovecot.conf" ''
    listen = "127.0.0.1, ::1, "
  '';
in
{

  services.dovecot2 = {
    enable = true;
    enablePop3 = true;
    enableImap = true;

    extraConfig = ''
      service auth {
        # Postfix smtp-auth over submission port
        unix_listener /var/lib/postfix/queue/private/auth {
          mode = 0666
        }
      }
    '';

    sslServerKey =
      if (cfg.sslCertificate != null && cfg.sslCertificateKey != null) then
        cfg.sslCertificateKey
      else
        "${certs.${cfg.domainName}.directory}/privkey.pem";
    sslServerCert =
      if (cfg.sslCertificate != null && cfg.sslCertificateKey != null) then
        cfg.sslCertificate
      else
        "${certs.${cfg.domainName}.directory}/fullchain.pem";
    sslCACert =
      if (cfg.sslCertificate != null && cfg.sslCertificateKey != null) then
        builtins.head config.security.pki.certificateFiles
      else
        "${certs.${cfg.domainName}.directory}/chain.pem";
  };
}

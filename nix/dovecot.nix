{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
  inherit (config.security.acme) certs;
  alaveteliPopUser = "alaveteli_pop_user";
in
{
  # the user that alaveteli uses to retrieve email via pop/dovecot
  # we use a system user and configure dovecot to use the passwd-file
  # auth method:
  # https://doc.dovecot.org/2.3/configuration_manual/authentication/passwd_file/#passwd-file
  users.users.alaveteliPopUser = {
    name = alaveteliPopUser;
    group = alaveteliPopUser;
    isSystemUser = true;
  };
  users.groups.${alaveteliPopUser} = { };

  services.dovecot2 = {
    enable = true;
    enablePop3 = true;
    enableImap = true;
    # disable PAM to allow non-unix users to receive email
    enablePAM = false;

    # duplicate lines in dovecot config are ok, only the last
    # line is considered.
    extraConfig = ''
      listen = "127.0.0.1, ::1"
      # auth_debug = yes
      # auth_debug_passwords=yes

      service auth {
        # Postfix smtp-auth over submission port
        unix_listener /var/lib/postfix/queue/private/auth {
          mode = 0666
        }
      }

      passdb {
        driver = passwd-file
        # use Blowfish encryption, allow username@domain login
        args = scheme=blf-crypt username_format=%n ${cfg.mailserver.imapPasswdFile}
      }

      userdb {
        driver = passwd-file
        args = username_format=%n ${cfg.mailserver.imapPasswdFile}
      }

      auth_mechanisms = plain login
    '';

    sslServerKey =
      if (cfg.sslCertificate != null && cfg.sslCertificateKey != null) then
        cfg.sslCertificateKey
      else
        "${certs.${cfg.domainName}.directory}/key.pem";
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

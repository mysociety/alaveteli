{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
in
{
  services.opendkim = {
    enable = true;
    selector = "mail";
    configFile = pkgs.writeText "opendkim.conf" ''
      # Log to syslog
      Syslog                  yes
      # Required to use local socket with MTAs that access the socket as a non-
      # privileged user (e.g. Postfix)
      UMask                   002

      Domain                  ${cfg.domainName}
      KeyFile                 /etc/dkimkeys/mail.private.key
      # Selector                mail
      # Socket                  local:/var/spool/postfix/var/run/opendkim/opendkim.sock
      # PidFile                 /var/spool/postfix/var/run/opendkim/opendkim.pid
      # UserID                  opendkim

      # Commonly-used options; the commented-out versions show the defaults.
      #Canonicalization       simple
      #Mode                   sv
      #SubDomains             no

      # Always oversign From (sign using actual From and a null From to prevent
      # malicious signatures header fields (From and/or others) between the signer
      # and the verifier.
      OversignHeaders         From

      ##  TrustAnchorFile filename
      ##      default (none)
      ##
      ## Specifies a file from which trust anchor data should be read when doing
      ## DNS queries and applying the DNSSEC protocol.  See the Unbound documentation
      ## at http://unbound.net for the expected format of this file.

      TrustAnchorFile       /usr/share/dns/root.key
    '';
  };
}

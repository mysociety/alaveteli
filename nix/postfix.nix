{
  config,
  lib,
  pkgPath,
  ...
}:
let
  cfg = config.services.alaveteli;
  inherit (config.security.acme) certs;

  # postfixServiceCfg = lib.optionalAttrs (cfg.mailserver.createLocally) {

in
{
  # TODO: possible bug in optionalAttrs when passed the postfix config???
  # using the line below breaks the eval
  # services.postfix = lib.optionalAttrs (cfg.mailserver.createLocally) {

  services.postfix = {
    enable = true;
    # enableSmtp = true; # port 25
    enableSubmission = true; # port 587
    rootAlias = cfg.mailserver.rootAlias;
    extraAliases = cfg.mailserver.extraAliases;
    submissionOptions = {
      smtpd_tls_security_level = "encrypt";
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "private/auth";
      smtpd_sasl_security_options = "noanonymous";
      smtpd_sasl_local_domain = "$myhostname";
      smtpd_client_restrictions = "permit_sasl_authenticated,reject";
      smtpd_sender_login_maps = "hash:/etc/postfix/virtual";
      smtpd_sender_restrictions = "reject_sender_login_mismatch";
      smtpd_recipient_restrictions = "reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject";
    };
  };

  services.postfix.settings.main = {
    myhostname = cfg.domainName;
    mydestination = [
      cfg.domainName
      "localhost.localdomain"
      "localhost"
    ];
    mynetworks = [
      "127.0.0.0/8"
      "[::ffff:127.0.0.0]/104"
      "[::1]/128"
    ];
    message_size_limit = 30720000;
    recipient_delimiter = "+";

    smtpd_tls_chain_files = [
      "${certs.${cfg.domainName}.directory}/privkey.pem"
      "${certs.${cfg.domainName}.directory}/fullchain.pem"
    ];
    smtpd_use_tls = "yes";
    smtpd_tls_session_cache_database = "btree:\${data_directory}/smtpd_scache";

    # TLS parameters for sending (postfix acting as a client)
    # try tls when sending ("encrypt" is too strict as multiple legitimate recipient
    # servers do not offer TLS yet, so we stick to opportunistic TLS)
    # https://www.postfix.org/TLS_README.html#client_tls_levels
    smtp_tls_security_level = "may";

    smtp_tls_session_cache_database = "btree:\${data_directory}/smtp_scache";

    # try to connect over ipv4 first to reduce problems with
    # blocklisted ipv6 address
    # Docs: https://www.postfix.org/postconf.5.html#smtp_address_preference
    smtp_address_preference = "ipv4";

    mailbox_size_limit = 0;

    smtpd_relay_restrictions = "permit_mynetworks permit_sasl_authenticated defer_unauth_destination";

    # explicitly set local_recipient_map to limit backscatter problems:
    # if a recipient does not exist, postfix will notify the sender immediately,
    # during the smtp exchange, instead of first accepting the email and then
    # sending an error message.
    # TODO: where does the local_recipient_maps file end up?
    local_recipient_maps = "proxy:unix:passwd.byname regexp:/etc/postfix/recipients";

    # TODO: figure out what happens with this, how do we build the mapping file?
    recipient_bcc_maps = "regexp:/etc/postfix/recipient_bcc";

    #
    # DKIM settings
    #
    # smtpd_milters: opendkim, rspamd
    # TODO: get these from cfg, but see services.rspamd.postfix.enable
    smtpd_milters = "local:/var/run/opendkim/opendkim.sock, inet:localhost:11332";
    non_smtpd_milters = config.services.opendkim.socket;
    # non_smtpd_milters = "local:/var/run/opendkim/opendkim.sock";

    # configure SASL auth via dovecot: see
    # https://doc.dovecot.org/2.3/configuration_manual/howto/postfix_and_dovecot_sasl/
    # https://www.postfix.org/SASL_README.html#server_sasl_enable
    smtpd_sasl_type = "dovecot";
    smtpd_sasl_path = "private/auth";
    smtpd_sasl_auth_enable = "yes";

    smtpd_sasl_security_options = "noanonymous";
    smtpd_sasl_tls_security_options = "$smtpd_sasl_security_options";
    smtpd_tls_auth_only = "yes";

    #
    # rspamd milter options
    #
    # skip mail without checks if something goes wrong
    milter_default_action = "accept";

    # 6 is the default milter protocol version;
    milter_protocol = 6;
  };

  services.postfix.settings.master = {

    alaveteli = {
      type = "unix";
      privileged = true;
      chroot = false;
      maxproc = 50;
      command = "pipe";
      args = [
        "flags=R"
        "user=alaveteli"
        "argv=${pkgPath}/script/mailin"
      ];
    };

    alaveteli_replies = {
      type = "unix";
      privileged = true;
      chroot = false;
      maxproc = 50;
      command = "pipe";
      args = [
        "flags=R"
        "user=alaveteli"
        "argv=${pkgPath}/script/handle-mail-replies"
      ];
    };

    # use this instead of enableSmtp to enable chrooting
    # which we need for dkim signing (?)
    smtp = {
      type = "inet";
      chroot = true;
      private = false;
      command = "smtpd";
      args = [ ];
    };
  };
}

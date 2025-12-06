{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
  inherit (config.security.acme) certs;

  insecureCiphers = [
    "ADH-AES128-SHA"
    "ADH-AES256-SHA"
    "ADH-AES128-GCM-SHA256"
    "ADH-AES256-GCM-SHA384"
    "ADH-AES128-SHA256"
    "ADH-AES256-SHA256"
    "ADH-CAMELLIA128-SHA"
    "ADH-CAMELLIA128-SHA256"
    "ADH-CAMELLIA256-SHA"
    "ADH-CAMELLIA256-SHA256"
    "AECDH-AES128-SHA"
    "AECDH-AES256-SHA"
  ];

  mtaStsPolicy = ''
    version: STSv1
    mode: ${cfg.mailserver.mtaStsMode}
    max_age: 10368000
    mx: ${cfg.domainName}
  '';
  incomingEmailPrefix = config.services.alaveteli.settings.general.INCOMING_EMAIL_PREFIX;
  incomingEmailPrefixNoPlus = builtins.replaceStrings [ "+" ] [ "" ] incomingEmailPrefix;
in
{
  # NOTE: the setup used here is a little unusual:
  # script/mailin is not used at all, instead we rely entirely on the pop mailer
  # to load incoming email for ALL accounts with it, whether pro is active or not
  services.postfix = {
    enable = true;
    enableSmtp = true; # port 25 (define config manually below)
    enableSubmission = true; # port 587
    localRecipients = [
      "/^${incomingEmailPrefixNoPlus}.*/"
      "/^postmaster@/"
      "/^abuse@/"
      "/^webmaster@/"
    ]
    ++ cfg.mailserver.localRecipients;
    transport = ''
      /^support-utilisateurs@${cfg.domainName}$/            alaveteli_replies
    '';

    extraAliases = ''
      abuse: root
      postmaster: root
      webmaster: root
      ${incomingEmailPrefixNoPlus}: ${config.users.users.alaveteliPopUser.name}, backupfoi
      ne-pas-repondre: /dev/null
    ''
    + cfg.mailserver.extraAliases;

    # https://doc.dovecot.org/2.3/configuration_manual/howto/postfix_and_dovecot_sasl/#using-sasl-with-postfix-submission-port
    # https://www.postfix.org/SASL_README.html#server_sasl_enable
    submissionOptions = {
      smtpd_tls_security_level = "encrypt";
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "private/auth";
      smtpd_sasl_security_options = "noanonymous";
      smtpd_sasl_tls_security_options = "$smtpd_sasl_security_options";
      smtpd_tls_auth_only = "yes";
      smtpd_sasl_local_domain = "$myhostname";
      smtpd_client_restrictions = "permit_sasl_authenticated,reject";
      smtpd_sender_restrictions = "reject_sender_login_mismatch";
      smtpd_recipient_restrictions = "reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject";
    };
  };

  # add postfix to opendkim group so it can access opendkim.sock
  users.users.${config.services.postfix.user}.extraGroups = [ config.services.opendkim.group ];

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

    # prefer our order of ciphers
    tls_preempt_cipherlist = "yes";

    # settings for mandatory encryption
    smtpd_tls_mandatory_ciphers = "high";
    smtpd_tls_mandatory_protocols = ">=TLSv1.2";
    smtpd_tls_mandatory_exclude_ciphers = builtins.concatStringsSep ", " insecureCiphers;
    # same for opportunistic encryption
    smtpd_tls_ciphers = "high";
    smtpd_tls_protocols = ">=TLSv1.2";
    # list based on https://internet.nl email tester
    smtpd_tls_exclude_ciphers = builtins.concatStringsSep ", " insecureCiphers;

    smtpd_tls_chain_files =
      if (cfg.sslCertificate != null && cfg.sslCertificateKey != null) then
        [
          cfg.sslCertificateKey
          cfg.sslCertificate
        ]
      else
        [
          "${certs.${cfg.domainName}.directory}/key.pem"
          "${certs.${cfg.domainName}.directory}/fullchain.pem"
        ];

    # TODO: "smtpd_use_tls" will be removed; instead, specify "smtpd_tls_security_level"
    # smtpd_use_tls = "yes";
    smtpd_tls_session_cache_database = "btree:\${data_directory}/smtpd_scache";

    # TLS parameters for sending (postfix acting as a client)
    # try tls when sending ("encrypt" is too strict as multiple legitimate recipient
    # servers do not offer TLS yet, so we stick to opportunistic TLS)
    # https://www.postfix.org/TLS_README.html#client_tls_levels
    smtp_tls_security_level = "dane";
    smtp_dns_support_level = "dnssec";

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
    local_recipient_maps = lib.mkForce "proxy:unix:passwd.byname regexp:/etc/postfix/local_recipients";

    #
    # DKIM settings
    #
    smtpd_milters = "${config.services.opendkim.socket}, inet:${(builtins.head config.services.rspamd.workers.rspamd_proxy.bindSockets).socket}";
    non_smtpd_milters = config.services.opendkim.socket;

    #
    # rspamd milter options
    #
    # skip mail without checks if something goes wrong
    milter_default_action = "accept";

    # 6 is the default milter protocol version;
    milter_protocol = 6;

    # default value is "hash:..." record, which does not work
    # with our regexp content in transports
    transport_maps = lib.mkForce "regexp:/etc/postfix/transport";
  };

  services.postfix.settings.master = {

    alaveteli_replies = {
      type = "unix";
      privileged = true;
      chroot = false;
      maxproc = 50;
      command = "pipe";
      args = [
        "flags=R"
        "user=alaveteli"
        "argv=${cfg.package}/script/handle-mail-replies"
      ];
    };
  };

  # MTA-STS for outbound email
  # https://wiki.archlinux.org/title/TLS-RPT,_DANE_and_MTA-STS#MTA-STS
  services.postfix-tlspol = {
    enable = true;
  };

  # MTA-STS for inbound email
  services.nginx.virtualHosts."mta-sts.${cfg.domainName}" = {
    inherit (cfg) sslCertificate sslCertificateKey;
    onlySSL = true;
    enableACME = (cfg.sslCertificate == null && cfg.sslCertificateKey == null);
    locations."=/.well-known/mta-sts.txt".alias = pkgs.writeText "well-known-mta-sts-txt" "${
      mtaStsPolicy
    }";
  };

  users.users.backupfoi = {
    name = "backupfoi";
    group = "backupfoi";
    isSystemUser = true;
  };
  users.groups.backupfoi = { };

}

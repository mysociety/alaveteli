# definition of the alaveteli service for production deployments
# Design decisions:
# alaveteli is run with puma and nginx (for opensource reasons)
# postfix for email, with opendkim, rspamd, dovecot for imap/pop

# self is the alaveteli flake
self:
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.services.alaveteli;
  filterNull = lib.filterAttrs (_: v: v != null);
  settingsFormat = pkgs.formats.yaml { };
  appListeningAddress = "127.0.0.1";
  appPort = 3000;
  railsMaxThreads = 3;

  # required for outbound connections to cloud storage, etc...
  # see in ./bundlerEnv.nix for version info
  sslFix = pkgs.writeText "rubyssl_default_store.rb" ''
    require "openssl"
    s = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    OpenSSL::SSL::SSLContext.send(:remove_const, :DEFAULT_CERT_STORE) rescue nil
    OpenSSL::SSL::SSLContext.const_set(:DEFAULT_CERT_STORE, s.freeze)
  '';

  alaveteliConfig = settingsFormat.generate "general.yml" (
    {
      DOMAIN = cfg.domainName;
      EXCEPTION_NOTIFICATIONS_FROM = "errors@${cfg.domainName}";
      FORCE_SSL = true;

      GEOIP_DATABASE = "${config.services.geoipupdate.settings.DatabaseDirectory}/GeoLite2-Country.mmdb";
      THEME_URLS = [
        "${cfg.theme.url}"
      ];
      MAXMIND_LICENSE_KEY = cfg.geoipLicenseKey;
      STAGING_SITE = 0;

      MTA_LOG_TYPE = "postfix";
      MTA_LOG_PATH = "/var/log/mail/mail.log-*";

      # how alaveteli retrieves incoming email
      PRODUCTION_MAILER_RETRIEVER_METHOD = "pop";
      POP_MAILER_ADDRESS = "localhost";
      POP_MAILER_PORT = 995;
      POP_MAILER_USER_NAME = config.users.users.alaveteliPopUser.name;

      # empty custom search path so AlaveteliExternalCommand
      # uses ENV["PATH"] instead
      UTILITY_SEARCH_PATH = [ ];

    }
    // cfg.settings.general
  );

  alaveteliPackage = pkgs.callPackage ./package.nix {
    customAlaveteliPatches = cfg.theme.customAlaveteliPatches;
    secretsFile = cfg.settings.secretsFile;
    themeGemfile = cfg.theme.gemfile;
    themeLockfile = cfg.theme.gemfileLock;
    themeGemset = cfg.theme.gemset;
    themeUrl = cfg.theme.url;
    themeFiles = cfg.theme.files;
    themeTranslationFiles = cfg.theme.translationFiles;
    themeProTranslationFiles = cfg.theme.proTranslationFiles;
    inherit (cfg) dataDir;
  };

  databaseConfig = settingsFormat.generate "database.yml" cfg.database.settings;

  defaultStorageConfig =
    lib.mkIf (cfg.settings.storage == null) settingsFormat.generate "storage.yml"
      {
        local = {
          service = "Disk";
          root = "${cfg.dataDir}/storage/local";
        };
        raw_emails = {
          service = "Disk";
          # can't use Rails.root here, as it would end up in /nix/store
          root = "${cfg.dataDir}/storage/raw_emails";
        };
        attachments = {
          service = "Disk";
          root = "${cfg.dataDir}/storage/attachments";
        };
      };

  environment = {
    LOGFILE = "${cfg.dataDir}/log/production.log";
    RAILS_ENV = "production";
    # env vars below are picked up by config/puma.rb
    RAILS_MAX_THREADS = toString railsMaxThreads;
    PORT = "${toString appPort}";
    RUBYOPT = "-r${sslFix}";
    # TODO: set the var and find where solid_queue is
    # SOLID_QUEUE_IN_PUMA = "true";
  };

  # mirrors the ruby function used in various scripts to get themeName from themeUrl
  themeName =
    with lib.strings;
    (builtins.head (splitString "." (lib.last (splitString "/" cfg.theme.url))));

  defaultThemePackage = pkgs.stdenvNoCC.mkDerivation {
    pname = themeName;
    version = "0.0.1";
    src = cfg.theme.files;
    # this is to prevent weird errors when there is a Makefile
    # in the theme folder
    buildPhase = "echo 'skipping buildPhase'";
    installPhase = "cp -R . $out";
  };

  themePackage =
    if themeName == "alavetelitheme" then
      pkgs.stdenvNoCC.mkDerivation {
        pname = "alavetelitheme";
        version = "9426f758";
        src = pkgs.fetchFromGitHub {
          owner = "mysociety";
          repo = "alavetelitheme";
          rev = "9426f7589cbd4393611c99c059332c613523682a";
          hash = "sha256-Mo2v8KBniikfxdSUAn8aVYtGmHcHkrmUrMy192GlozI=";
        };
        installPhase = "cp -R . $out";
      }
    else
      cfg.theme.package;

  # use the user provided certs or default to letsencrypt ones
  domainCertFile =
    if (cfg.sslCertificate != null && cfg.sslCertificateKey != null) then
      cfg.sslCertificate
    else
      "${config.security.acme.certs.${cfg.domainName}.directory}/fullchain.pem";

  generateTlsaRecord =
    # bash
    ''
      export CERT_CONTENTS=`cat ${domainCertFile}`
      ${pkgs.curl}/bin/curl --no-progress-meter \
        'https://www.huque.com/bin/gen_tlsa' \
        -X POST \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "cert=''${CERT_CONTENTS}" \
        --data-raw 'usage=3&selector=1&mtype=1&port=25&transport=tcp&domain=${cfg.domainName}&Generate=Generate' |
        ${pkgs.ripgrep}/bin/rg -A4 '<div class="tlsa_rec">' |
        tail -n3 |
        ${pkgs.gnused}/bin/sed -z 's/\n//g' |
        ${pkgs.gnused}/bin/sed 's/ \{2,\}//g' |
        ${pkgs.gnused}/bin/sed 's/(//g'
    '';
  serverIPv4Address =
    # bash
    ''
      ${pkgs.nettools}/bin/ifconfig | ${pkgs.ripgrep}/bin/rg 'inet ' | ${pkgs.ripgrep}/bin/rg -v '127.0.0.1' | ${pkgs.gawk}/bin/awk '{ print $2}'
    '';
  serverIPv6Address =
    # bash
    ''
      ${pkgs.nettools}/bin/ifconfig | ${pkgs.ripgrep}/bin/rg 'inet6 .*global' | ${pkgs.gawk}/bin/awk '{ print $2}'
    '';
in
{
  imports = [
    (import ./cron_jobs.nix {
      inherit config lib pkgs;
    })
    (import ./dovecot.nix {
      inherit config lib pkgs;
    })
    (import ./opendkim.nix {
      inherit config pkgs;
    })
    (import ./logrotate.nix {
      inherit config pkgs;
    })
    (import ./postfix.nix {
      inherit config lib pkgs;
    })
    (import ./postgresql.nix {
      inherit config lib pkgs;
    })
    (import ./rspamd.nix {
      inherit config inputs;
    })
    (import ./ssh.nix {
      inherit config lib pkgs;
    })
  ];
  options = {
    services.alaveteli = {

      enable = lib.mkEnableOption "Alaveteli, a Freedom of Information request system for your jurisdiction";

      package = lib.mkOption {
        type = lib.types.package;
        default = alaveteliPackage;
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "alaveteli";
        description = ''
          Name of the Alaveteli user.
        '';
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "alaveteli";
        description = ''
          Name of the Alaveteli group.
        '';
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/alaveteli";
        description = ''
          Path to a folder that will contain Alaveteli working directory.
        '';
      };

      domainName = lib.mkOption {
        type = lib.types.str;
        description = "The domain name on which your site will run";
        example = "example.com";
      };

      settings = {
        general = lib.mkOption {
          type = settingsFormat.type;
          description = "Settings that should go in config/general.yml. These get merged with default settings.";
          default = { };
          example = {
            ISO_COUNTRY_CODE = "en";
            SITE_NAME = "My FOI Site";
          };
        };
        secretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to a file with settings that should go in config/general.yml but not appear in the nix store. They get passed to alaveteli services as env vars, prefix your values with ALAVETELI_.";
        };
        storageConfigFile = lib.mkOption {
          type = with lib.types; nullOr path;
          default = null;
          description = ''
            Path to the file to be used by Rails as config/storage.yml.
            The default will create a basic local file storage.
          '';
        };
      };

      theme = {
        url = lib.mkOption {
          type = lib.types.str;
          description = "The url for the repository of the theme to use";
          default = "https://github.com/mysociety/alavetelitheme.git";
          example = "https://github.com/mysociety/someothertheme.git";
        };
        files = lib.mkOption {
          type = with lib.types; nullOr path;
          default = null;
          description = "Path to the theme files in the repo (relative to nix file)";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = defaultThemePackage;
        };
        translationFiles = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
          description = "Attribute set of locale = path_to_po_file";
        };
        proTranslationFiles = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
          description = "Attribute set of locale = path_to_po_file";
        };
        gemfile = lib.mkOption {
          type = with lib.types; nullOr path;
          description = "Gemfile to be used by alaveteli, leave empty if the theme requires no extra gems";
          default = ../Gemfile;
        };
        gemfileLock = lib.mkOption {
          type = with lib.types; nullOr path;
          default = ../Gemfile.lock;
        };
        gemset = lib.mkOption {
          type = with lib.types; nullOr path;
          default = ../gemset.nix;
        };
        customAlaveteliPatches = lib.mkOption {
          type = with lib.types; listOf path;
          default = [ ];
          description = "A list of paths to patches to be applied to the alaveteli source code";
          example = "[ ./path/to/patch ]";
        };
      };

      geoipLicenseKey = lib.mkOption {
        type = with lib.types; either path (attrsOf path);
        description = ''
          A file containing the MaxMind license key.

          Always handled as a secret whether the value is
          wrapped in a `{ _secret = ...; }`
          attrset or not (refer to [](#opt-services.geoipupdate.settings) for
          details).
        '';
      };

      sslCertificate = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        example = "/run/keys/ssl.cert";
        description = ''
          The path to the server SSL certificate. If unset, a certificate
          will be created using letsencrypt.
        '';
      };

      sslCertificateKey = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        example = "/run/keys/ssl.key";
        description = ''
          The path to the server SSL certificate key. If unset, a certificate
          will be created using letsencrypt.
        '';
      };

      database = {
        host = lib.mkOption {
          type = lib.types.str;
          default = "/run/postgresql";
          description = ''
            Database host address.
          '';
        };

        port = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          description = "Database port. Use `null` for default port.";
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = "alaveteli";
          description = ''
            Database name.
          '';
        };

        user = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "foi";
          description = "Database user.";
        };

        passwordFile = lib.mkOption {
          type = lib.types.path;
          # default = null;
          example = "/run/keys/alaveteli-dbpassword";
          description = ''
            A file containing the password for {option}`services.alaveteli.database.user`.
          '';
        };

        createLocally = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to create a local database automatically.";
        };

        settings = lib.mkOption {
          type = settingsFormat.type;
          default = { };
          example = lib.literalExpression ''
            {
            }
          '';
          description = ''
            The {file}`database.yml` configuration file as key value set.
            See \<TODO\>
            for list of configuration parameters.
          '';
        };

        backup = {
          # docs: https://wal-g.readthedocs.io/#storage
          # https://wal-g.readthedocs.io/STORAGES/#s3
          # https://wal-g.readthedocs.io/PostgreSQL/
          enable = lib.mkEnableOption "postgres backup with wal-g";

          s3AccessKeyId = lib.mkOption {
            type = lib.types.str;
            description = "Access key id for the s3 compatible storage for postgres backups";
          };
          s3SecretAccessKey = lib.mkOption {
            type = lib.types.str;
            description = "Secret Access key for the s3 compatible storage for postgres backups";
          };
          s3Prefix = lib.mkOption {
            type = lib.types.str;
            description = "Prefix for the s3 compatible storage for postgres backups";
            example = "s3://bucket/path";
          };
          s3Endpoint = lib.mkOption {
            type = lib.types.str;
            description = "Endpoint for the s3 compatible storage for postgres backups";
            example = "https://location.example.com";
            default = "";
          };
          s3Region = lib.mkOption {
            type = lib.types.str;
            description = "Region for the s3 compatible storage for postgres backups";
          };
          libsodiumWalgKeyPath = lib.mkOption {
            type = lib.types.path;
            description = "Path to a key for libsodium encryption of backups, generated with `openssl rand -hex 32`.";
          };
        };
      };

      redis = {
        createLocally = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to create a local redis automatically.";
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = "alaveteli";
          description = ''
            Name of the redis server. Only used if `createLocally` is set to true.
          '';
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = ''
            Redis server address.
          '';
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 6379;
          description = "Port of the redis server.";
        };
      };

      mailserver = {
        createLocally = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to create a local postfix automatically.
            If false, no email services are configured (postfix, opendkim, rspamd).
          '';
        };
        imapPasswdFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Full path to a file containing the passwd-file accounts.
            See: https://doc.dovecot.org/2.3/configuration_manual/authentication/passwd_file/#passwd-file for the expected file format
          '';
          example = "/run/secrets/imap.passwd";
        };
        aliasFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to a postfix alias file that is typically an encrypted
            template listing email aliases. Format:
            <alias>: <email to forward to>
          '';
        };
        localRecipients = lib.mkOption {
          type = with lib.types; (listOf str);
          default = [ ];
          description = ''
            List of accepted local users. Specify a bare username, an
            `"@domain.tld"` wild-card, or a complete
            `"user@domain.tld"` address. This should be set to help reduce backscatter:
            if a recipient does not exist, postfix will notify the sender immediately,
            during the smtp exchange, instead of first accepting the email and then
            sending an error message (which would increase your volume of spam-looking
            outgoing emails and lower your reputation).
            `postmaster` and request "magic" emails are automatically added to this list.
          '';
        };
        extraAliases = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            Email aliases, copied verbatim into postfix aliases config file.
          '';
        };
        mtaStsMode = lib.mkOption {
          type = lib.types.enum [
            "testing"
            "enforce"
          ];
          description = ''
            The mode for the MTA-STS policy for the email server. Do not turn on "enforce"
            until the testing period results look acceptable, or you might have email
            delivery issues.
          '';
          default = "testing";
        };
      };

    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = (cfg.sslCertificate != null) -> (cfg.sslCertificateKey != null);
        message = "If sslCertificate is set, sslCertificateKey must be set as well. Unset both to use letsencrypt instead.";
      }
    ];

    # packages required to deploy and run alaveteli
    # tools required to build ruby gems and such do NOT go here
    environment.systemPackages = [
      cfg.package.rails
      cfg.package.rake
      pkgs.curl
      pkgs.dig
      pkgs.git
      pkgs.gnused
      pkgs.ripgrep
      pkgs.urlencode
      pkgs.wkhtmltopdf
    ];

    services.alaveteli.database.settings = {
      production = lib.mapAttrs (_: v: lib.mkDefault v) (filterNull {
        adapter = "postgresql";
        database = cfg.database.name;
        encoding = "utf8";
        host = cfg.database.host;
        password = "<%= begin IO.read('${cfg.database.passwordFile}') rescue '' end %>";
        pool = railsMaxThreads + 2;
        port = cfg.database.port;
        template = "template_utf8";
        timeout = 5000;
        username = cfg.database.user;
      });
    };

    networking.firewall.allowedTCPPorts = [
      25
      80
      443
    ];

    users.users.${cfg.user} = {
      group = "${cfg.group}";
      # postdrop allows cron jobs running as alaveteli to use
      # the postdrop "emailing" utility. See man 1 postdrop
      extraGroups = [ "postdrop" ];
      isSystemUser = true;
    };

    users.groups.${cfg.group} = { };

    # prevent manually adding/changing system users, they need to
    # be defined in nix config
    users.mutableUsers = false;

    services.memcached = {
      enable = true;
    };

    services.redis = lib.optionalAttrs cfg.redis.createLocally {
      servers."${cfg.redis.name}" = {
        enable = true;
        port = cfg.redis.port;
      };
    };

    # TODO: add systemd job to upgrade alaveteli (see example in nextcloud module)
    services.nginx = {
      enable = lib.mkDefault true;

      virtualHosts.${cfg.domainName} = {
        inherit (cfg) sslCertificate sslCertificateKey;
        forceSSL = true;
        enableACME = (cfg.sslCertificate == null && cfg.sslCertificateKey == null);
        locations."/" = {
          proxyPass = "http://${appListeningAddress}:${toString appPort}";
          recommendedProxySettings = true;
        };
        extraConfig = ''
          client_max_body_size 15M;
          access_log /var/log/nginx/alaveteli_ssl_access.log;
          error_log /var/log/nginx/alaveteli_ssl_error.log error;
        '';
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "root@${cfg.domainName}";
    };

    users.users."geoip" = {
      group = "geoip";
      isSystemUser = true;
    };
    users.groups.geoip = { };

    services.geoipupdate = {
      # enable = (cfg.geoipLicenseKey != null);
      enable = lib.trace cfg.geoipLicenseKey false;
      settings = {
        EditionsIDs = [
          "GeoLite2-Country"
        ];
        LicenseKey = cfg.geoipLicenseKey;
      };
    };

    # TODO: configure varnish

    # systemd services

    systemd.services.alaveteli-puma = {
      inherit environment;

      description = "Alaveteli web service";
      requires =
        lib.optionals (cfg.database.createLocally) [ "postgresql.service" ]
        ++ lib.optionals cfg.redis.createLocally [ "redis-${cfg.redis.name}.service" ];
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "systemd-tmpfiles-setup.service"
      ]
      ++ lib.optionals (cfg.database.createLocally) [ "postgresql.service" ]
      ++ lib.optionals cfg.redis.createLocally [ "redis-${cfg.redis.name}.service" ];
      script = "./bin/puma -C config/puma.rb -b tcp://${appListeningAddress}:${toString appPort}";
      preStop = "./bin/pumactl stop -F config/puma.rb";
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";

        User = cfg.user;
        Group = cfg.group;
        PrivateTmp = true;
        StateDirectory = "alaveteli";

        EnvironmentFile = cfg.settings.secretsFile;

        WorkingDirectory = cfg.package;
        TimeoutStartSec = 1200;
        RestartSec = 1;
        # watchDogSec = 10;
        # hardening
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        NoNewPrivileges = true;
        SystemCallFilter = "~@clock @cpu-emulation @debug @module @mount @reboot @swap";
      };

      # make these programs available to the alaveteli service
      path = [
        cfg.package
        pkgs.catdoc
        pkgs.elinks
        pkgs.git
        pkgs.pdftk
        pkgs.poppler-utils
        pkgs.unrtf
        pkgs.unzip
        pkgs.wkhtmltopdf
        pkgs.wv # wvText handles doc files
      ];

      # This preStart script replaces rails-post-deploy
      # nixos converts this to a separate systemd unit that is run before the main one
      # TODO: how to run version specific scripts? how to find old/new version?
      preStart =
        # bash
        ''
          mkdir -p ${cfg.dataDir}/lib/themes
          rm -f ${cfg.dataDir}/lib/themes/${themeName}
          ln -s ${themePackage} ${cfg.dataDir}/lib/themes/${themeName}
          mkdir -p ${cfg.dataDir}/cache
          mkdir -p ${cfg.dataDir}/config
          mkdir -p ${cfg.dataDir}/log
          mkdir -p ${cfg.dataDir}/tmp
          cat ${databaseConfig} > ${cfg.dataDir}/config/database.yml
          rm -f ${cfg.dataDir}/config/storage.yml
          ${
            if cfg.settings.storageConfigFile == null then
              ''
                cat ${defaultStorageConfig} > ${cfg.dataDir}/config/storage.yml
              ''
            else
              ''
                ln -s ${cfg.settings.storageConfigFile} ${cfg.dataDir}/config/storage.yml
              ''
          }
          cat ${alaveteliConfig} > ${cfg.dataDir}/config/general.yml

          # some of the rails-post-deploy script is run during package
          # compilation instead of service startup, which allows caching
          # between deployments, and is also needed for readonlyness of
          # the produced site code base

          rake db:migrate
          # seeding causes some non-fatal error messages in postgres
          # logs when it tries to insert duplicate flipper_features
          rake db:seed

          # ensure we have a xapian db if it does not exist
          if [ ! -f ${cfg.dataDir}/xapiandbs/${environment.RAILS_ENV}/iamglass ]; then
              rake --silent "$@" xapian:destroy_and_rebuild_index models="PublicBody User InfoRequestEvent"
          fi

          # TODO: run the install and post_install.rb hooks before starting the
          # actual service (see themes.rake / install_theme)
          # (this is only used on BE/UK for now, not urgent)
        '';
    };

    system.activationScripts.showDNSrecords = {
      text =
        # bash
        ''
          #!/bin/sh
          echo "########################################################"
          echo "DNS records to set for Alaveteli"
          echo "${cfg.domainName} A `${serverIPv4Address}`"
          echo "--------------------------------------------------------"
          echo "${cfg.domainName} AAAA `${serverIPv6Address}`"
          echo "--------------------------------------------------------"
          echo "${cfg.domainName} IN MX 10 ${cfg.domainName}.  (do not forget the dot at the end!)"
          echo "--------------------------------------------------------"
          echo 'SPF: ${cfg.domainName} 300 IN TXT "v=spf1 mx ~all"'
          echo "--------------------------------------------------------"
          echo "TLSA record:"
          ${generateTlsaRecord}
          echo
          echo "--------------------------------------------------------"
          echo "${cfg.domainName} CAA  0 issue \"letsencrypt.org\""
          echo "--------------------------------------------------------"
          echo "DKIM record:"
          cat /var/lib/opendkim/keys/${config.services.opendkim.selector}.txt
          echo "--------------------------------------------------------"
          echo "DMARC record:"
          echo '_dmarc.${cfg.domainName} TXT "v=DMARC1; p=quarantine;"'
          echo "--------------------------------------------------------"
          echo "MTA-STS and TLS-RPT records"
          echo "mta-sts.${cfg.domainName}   300   A      `${serverIPv4Address}`"
          echo "mta-sts.${cfg.domainName}   300   AAAA   `${serverIPv6Address}`"
          echo '_mta-sts.${cfg.domainName}  300  TXT  "v=STSv1; id=20251028T090000;"'
          echo '_smtp._tls.${cfg.domainName} 300 TXT "v=TLSRPTv1; rua=mailto:<your_email_address>;"  (use an address on another domain/server)'
          echo "--------------------------------------------------------"
          echo "Do not forget to set the reverse DNS to ${cfg.domainName}"
          echo "########################################################"
        '';
    };
    system.preSwitchChecks = {
      # return false/non-0 in any check to prevent the new config from being activated
      verifyDNSConfig =
        # bash
        ''
          echo "#####################################"
          echo "Verifying DNS config (A/AAAA records)"
          IPV4ADD=$(${serverIPv4Address})
          IPV6ADD=$(${serverIPv6Address})
          ${pkgs.dig}/bin/dig A ${cfg.domainName} | ${pkgs.ripgrep}/bin/rg "$IPV4ADD"
          ${pkgs.dig}/bin/dig AAAA ${cfg.domainName} | ${pkgs.ripgrep}/bin/rg "$IPV6ADD"
          echo "#####################################"
        '';
    };

  };

  meta.maintainers = with lib.maintainers; [ laurents ];
}

# definition of the alaveteli service for production deployments
# Design decisions:
# alaveteli is run with puma and nginx (for opensource reasons)
# postfix for email, with opndkim, rspamd
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # forEachSystem = lib.genAttrs (import systems);
  cfg = config.services.alaveteli;
  filterNull = lib.filterAttrs (_: v: v != null);
  settingsFormat = pkgs.formats.yaml { };
  appListeningAddress = "127.0.0.1";
  appPort = 3000;
  railsMaxThreads = 3;
  # the hostname used in alaveteli-server-test.nix

  alaveteliConfig = settingsFormat.generate "general.yml" {
    # drop emails in /tmp/mails while debugging
    PRODUCTION_MAILER_DELIVERY_METHOD = "file";
  };

  databaseConfig = settingsFormat.generate "database.yml" cfg.database.settings;

  storageConfig = settingsFormat.generate "storage.yml" {

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
    # TODO: set the var and find where solid_queue is
    # SOLID_QUEUE_IN_PUMA = "true";
  };
  # common service config
  serviceConfig = {
    Type = "simple";
    Restart = "no"; # TODO: remove this once it works
    # Restart = "always";

    User = cfg.user;
    Group = cfg.group;
    PrivateTmp = true;
    StateDirectory = "alaveteli";
    WorkingDirectory = package;
  };
  package = pkgs.callPackage ./package.nix {
    mkBundleEnv = pkgs.callPackage ./bundleEnv.nix { };
  };

in
{
  imports = [
    (import ./postfix.nix {
      inherit config lib;
      pkgPath = package;
    })
    (import ./rspamd.nix {
      inherit config lib;
    })
  ];
  options = {
    services.alaveteli = {

      enable = lib.mkEnableOption "Alaveteli, a Freedom of Information request system for your jurisdiction";

      # TODO: how to fix this option if package is not in nixpkgs?
      # package = lib.mkPackageOption "alaveteli" { };

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
          default = "alaveteli";
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

        rootAlias = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            Email address that should receive mail for root@ and postmaster@.
            Multiple values can be separated by commas.
            Leave empty for no redirection.
          '';
        };
        extraAliases = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            Email aliases, copied verbatim into postfix aliases config file.
          '';
        };
      };

    };
  };

  config = lib.mkIf cfg.enable {

    # TODO: where do we put packages required by the service?
    # environment.systemPackages = with pkgs; [ git wkhtmltopdf ];

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
      80
      443
    ];

    users.users.${cfg.user} = {
      group = "${cfg.group}";
      isSystemUser = true;
    };

    users.groups.${cfg.group} = { };

    services.memcached = {
      enable = true;
    };

    services.postgresql = lib.optionalAttrs (cfg.database.createLocally) {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
        }
      ];
    };

    services.redis = lib.optionalAttrs cfg.redis.createLocally {
      servers."${cfg.redis.name}" = {
        enable = true;
        port = cfg.redis.port;
      };
    };

    # TODO: configure opendkim

    # TODO: configure rspamd

    # TODO: add systemd job to run alaveteli

    # TODO: add systemd job to upgrade alaveteli (see example in nextcloud module)
    # must run rails-post-deploy

    # TODO: configure nginx
    services.nginx = {
      enable = lib.mkDefault true;

      virtualHosts.${cfg.domainName} = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${appListeningAddress}:${toString appPort}";
          recommendedProxySettings = true;
        };
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
      serviceConfig = serviceConfig // {
        TimeoutStartSec = 1200;
        RestartSec = 1;
        # watchDogSec = 10;
      };

      # make these programs available to the alaveteli service
      path = [
        package
        pkgs.git
      ];

      # TODO: should this be here or in a separate service definition? (and rails-post-deploy?)
      preStart = ''
        mkdir -p ${cfg.dataDir}/config
        mkdir -p ${cfg.dataDir}/log
        mkdir -p ${cfg.dataDir}/tmp
        cat ${databaseConfig} > ${cfg.dataDir}/config/database.yml
        cat ${storageConfig} > ${cfg.dataDir}/config/storage.yml
        cat ${alaveteliConfig} > ${cfg.dataDir}/config/general.yml

        ./script/rails-deploy-while-down
      '';
    };

  };

  meta.maintainers = with lib.maintainers; [ laurents ];
}

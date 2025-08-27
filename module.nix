# definition of the alaveteli service for production deployments
# Design decisions:
# alaveteli is run with puma and nginx (for opensource reasons)
# postfix for email, with opndkim, rspamd
{ config, lib, pkgs, ... }:
let
  # forEachSystem = lib.genAttrs (import systems);
  cfg = config.services.alaveteli;
  filterNull = lib.filterAttrs (_: v: v != null);
  settingsFormat = pkgs.formats.yaml { };
  appPort = 3000;
  railsMaxThreads = 3;
  databaseConfig = settingsFormat.generate "database.yml" cfg.database.settings;
  environment = {
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
    WorkingDirectory = package; # cfg.dataDir;
  };
  # package = cfg.package;
  package = pkgs.callPackage ./package.nix {
    mkBundleEnv = pkgs.callPackage ./bundleEnv.nix { };
  };

in {
  options = {
    services.alaveteli = {

      enable = lib.mkEnableOption
        "Alaveteli, a Freedom of Information request system for your jurisdiction";

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
          description = "Whether to create a local postfix automatically.";
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
        password =
          "<%= begin IO.read('${cfg.database.passwordFile}') rescue '' end %>";
        pool = railsMaxThreads + 2;
        port = cfg.database.port;
        template = "template_utf8";
        timeout = 5000;
        username = cfg.database.user;
      });
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    users.users.${cfg.user} = {
      group = "${cfg.group}";
      isSystemUser = true;
    };

    users.groups.${cfg.group} = { };

    services.postgresql = lib.optionalAttrs (cfg.database.createLocally) {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [{
        name = cfg.database.user;
        ensureDBOwnership = true;
      }];
    };

    services.redis = lib.optionalAttrs cfg.redis.createLocally {
      servers."${cfg.redis.name}" = {
        enable = true;
        port = cfg.redis.port;
      };
    };

    services.postfix =
      lib.optionalAttrs (cfg.mailserver.createLocally) { enable = true; };

    # TODO: configure opendkim

    # TODO: configure rspamd

    # TODO: add systemd job to run alaveteli

    # TODO: add systemd job to upgrade alaveteli (see example in nextcloud module)
    # must run rails-post-deploy

    # TODO: configure nginx
    services.nginx.enable = lib.mkDefault true;

    services.nginx.virtualHosts.${cfg.domainName} = {
      forceSSL = (cfg.domainName != "alaveteli.test");
      enableACME = (cfg.domainName != "alaveteli.test");
    };

    # TODO: configure varnish

    # systemd services

    systemd.services.alaveteli-puma = {
      inherit environment;

      description = "Alaveteli web service";
      requires =
        lib.optionals (cfg.database.createLocally) [ "postgresql.service" ]
        ++ lib.optionals cfg.redis.createLocally
        [ "redis-${cfg.redis.name}.service" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "systemd-tmpfiles-setup.service" ]
        ++ lib.optionals (cfg.database.createLocally) [ "postgresql.service" ]
        ++ lib.optionals cfg.redis.createLocally
        [ "redis-${cfg.redis.name}.service" ];
      script = "./bin/puma -C config/puma.rb";
      serviceConfig = serviceConfig // {
        TimeoutStartSec = 1200;
        # ExecStop = "bundle exec pumactl stop -F config/puma.rb";
        RestartSec = 1;
        # watchDogSec = 10;
      };

      # make these programs available to the alaveteli service
      path = [ pkgs.git ];

      # TODO: should this be here or in a separate service definition? (and rails-post-deploy?)
      preStart = ''
        mkdir -p ${cfg.dataDir}/config
        mkdir -p ${cfg.dataDir}/log
        mkdir -p ${cfg.dataDir}/tmp
        cat ${databaseConfig} > ${cfg.dataDir}/config/database.yml
      '';
    };

  };

  meta.maintainers = with lib.maintainers; [ laurents ];
}

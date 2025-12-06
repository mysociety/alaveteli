{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
  # env vars passed to wal-g
  walg_environment = {
    WALG_LIBSODIUM_KEY_TRANSFORM = "hex";
    WALG_COMPRESSION_METHOD = "zstd";
    # PGUSER = config.users.users.db_backup_user.name;
    PGUSER = config.users.users.postgres.name;
    PGHOST = "/run/postgresql";
  };
in
{
  environment.systemPackages = [
    pkgs.wal-g
  ];

  services.postgresql = lib.optionalAttrs (cfg.database.createLocally) {
    enable = true;
    ensureDatabases = [ cfg.database.name ];
    ensureUsers = [
      {
        name = cfg.database.user;
      }
    ];
    authentication = ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local  ${cfg.database.name}  ${cfg.database.user}  peer map=alaveteliUsers
    '';

    identMap = ''
      alaveteliUsers ${cfg.user} ${cfg.database.user}
    '';

    checkConfig = true;
    # do not upgrade to pg 18 yet, as it's not clear whether
    # it is supported by ruby gem pg v1.5.9
    # https://deveiate.org/code/pg/CHANGELOG_md.html
    package = pkgs.postgresql_17;

    settings = lib.optionalAttrs (cfg.database.backup.enable) {
      archive_mode = "on";
      archive_command = "${toString pkgs.wal-g}/bin/wal-g --config ${cfg.database.backup.storageConfigFile} wal-push %p";
    };
  };
  systemd.services.postgresql.environment = walg_environment;

  # why does this result in merging the various items of SystemCallFilter?
  # this is required to run wal-g wal-push. Without this seccomp setting,
  # wal-g is killed with a sigsys immediately.
  systemd.services.postgresql.serviceConfig.SystemCallFilter = [ "setrlimit" ];

  system.activationScripts.make-sh-visible-to-pg-walg = {
    text = ''
      ln -snf "${pkgs.bash}/bin/sh" /bin/sh
    '';
  };
  systemd.timers."wal-g-base-backup" =
    lib.optionalAttrs (cfg.database.createLocally && cfg.database.backup.enable)
      {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 04:07:00 UTC";
          Unit = "wal-g-base-backup.service";
        };
      };

  systemd.services."wal-g-base-backup" =
    lib.optionalAttrs (cfg.database.createLocally && cfg.database.backup.enable) {
      # pass secrets as a file via the --config option, and other settings
      # as env vars (in https://github.com/spf13/viper env vars take precedence
      # over config files)
      environment = walg_environment;
      script = ''
        set -eu
        ${pkgs.wal-g}/bin/wal-g --config ${cfg.database.backup.storageConfigFile} backup-push ${config.services.postgresql.dataDir}
      '';
      serviceConfig = {
        Type = "oneshot";
        User = config.users.users.postgres.name;
      };
    };

}

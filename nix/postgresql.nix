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
      archive_command = "${toString pkgs.wal-g}/bin/wal-g --config ${
        config.sops.templates."wal-g-backup.env".path
      } wal-push %p";
    };
  };

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

  sops.templates."wal-g-backup.env" = lib.optionalAttrs (cfg.database.backup.enable) {
    content = ''
      PGUSER=postgres
      PGHOST=/run/postgresql
      PGPASSWORD = ""
      AWS_ACCESS_KEY_ID = "${cfg.database.backup.s3AccessKeyId}"
      AWS_SECRET_ACCESS_KEY = "${cfg.database.backup.s3SecretAccessKey}"
      WALG_S3_PREFIX = "${cfg.database.backup.s3Prefix}"
      AWS_ENDPOINT = "${cfg.database.backup.s3Endpoint}"
      AWS_REGION = "${cfg.database.backup.s3Region}"
      WALG_LIBSODIUM_KEY_PATH = "${toString cfg.database.backup.libsodiumWalgKeyPath}"
      WALG_LIBSODIUM_KEY_TRANSFORM = "hex"
      WALG_COMPRESSION_METHOD = "zstd"
    '';
    owner = "postgres";
  };

  systemd.services."wal-g-base-backup" =
    lib.optionalAttrs (cfg.database.createLocally && cfg.database.backup.enable)
      {
        script = ''
          set -eu
          ${pkgs.wal-g}/bin/wal-g --config ${
            config.sops.templates."wal-g-backup.env".path
          } backup-push ${config.services.postgresql.dataDir}
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "postgres";
        };
      };

}

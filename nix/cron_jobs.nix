{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
  after = [
    "syslog.target"
    "network.target"
  ];

  commonServiceConfig = {
    Type = "simple";
    User = cfg.user;
    Group = cfg.group;
    EnvironmentFile = cfg.settings.secretsFile;
    WorkingDirectory = cfg.package;
    StandardError = "inherit";
    Restart = "on-failure";
    RestartSec = 1;
    # hardening
    ProtectClock = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    NoNewPrivileges = true;
    SystemCallFilter = "~@clock @cpu-emulation @debug @module @mount @reboot @swap";
  };
  environment = {
    RAILS_ENV = "production";
    RUBYOPT = "-r${sslFix}";
  };
  pkgPath = cfg.package.outPath;
  servicePath = [ pkgs.git ];

  # required for outbound connections to cloud storage, etc...
  # see in ./bundlerEnv.nix for version info
  sslFix = pkgs.writeText "rubyssl_default_store.rb" ''
    require "openssl"
    s = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    OpenSSL::SSL::SSLContext.send(:remove_const, :DEFAULT_CERT_STORE) rescue nil
    OpenSSL::SSL::SSLContext.const_set(:DEFAULT_CERT_STORE, s.freeze)
  '';
  wantedBy = [ "multi-user.target" ];
in
{
  systemd.services.alaveteli-poll-for-incoming = lib.optionalAttrs cfg.enable {
    inherit after environment wantedBy;

    description = "Import incoming mail into Alaveteli";
    path = servicePath;
    serviceConfig = commonServiceConfig // {
      ExecStart = "${cfg.package.rails}/bin/rails-alaveteli runner AlaveteliMailPoller.poll_for_incoming_loop";
      StandardOutput = "append:${cfg.dataDir}/log/poll-for-incoming.service.log";
    };
  };

  systemd.services.alaveteli-send-notifications = lib.optionalAttrs cfg.enable {
    inherit after environment wantedBy;

    description = "Send Alaveteli notifications";
    path = servicePath;
    serviceConfig = commonServiceConfig // {
      ExecStart = "${cfg.package.rails}/bin/rails-alaveteli runner NotificationMailer.send_notifications_loop";
      StandardOutput = "append:${cfg.dataDir}/log/send-notifications.service.log";
    };
  };

  systemd.services.alaveteli-alert-tracks = {
    inherit after environment wantedBy;

    description = "Send Alaveteli email alerts";
    path = servicePath;
    serviceConfig = commonServiceConfig // {
      ExecStart = "${cfg.package.rails}/bin/rails-alaveteli runner TrackMailer.alert_tracks_loop";
      StandardOutput = "append:${cfg.dataDir}/log/alert-tracks.service.log";
    };
  };

  systemd.services.alaveteli-sidekiq = {
    inherit after environment wantedBy;

    description = "Process sidekiq job queue for Alaveteli ";
    path = servicePath;
    serviceConfig = commonServiceConfig // {
      Type = "notify";
      Restart = "always";
      ExecStart = "${cfg.package}/bin/sidekiq -e production";
      StandardOutput = "append:${cfg.dataDir}/log/sidekiq.service.log";
      UMask = "0002";
      WatchdogSec = 10;
    };
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.lockfileProgs # used by run-with-lockfile.sh
  ];

  systemd.services.cron.path = [
    pkgs.xapian # xapian-compact is called in compact-xapian-database
  ];

  services.cron = {
    enable = true;
    systemCronJobs = [
      # Every 5 minutes
      "*/5 * * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/change-xapian-database.lock '${pkgPath}/script/update-xapian-index flush=true verbose=true' >> ${cfg.dataDir}/log/update-xapian-index.log || echo 'stalled?'"
      # Every 10 minutes
      "0,10,20,30,40,50 * * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/send-batch-requests.lock ${pkgPath}/script/send-batch-requests || echo 'stalled?'"

      # Once an hour
      "09 * * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/alert-comment-on-request.lock ${pkgPath}/script/alert-comment-on-request || echo 'stalled?'"
      "31 * * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/load-mail-server-logs.lock ${pkgPath}/script/load-mail-server-logs || echo 'stalled?'"

      # Once a day, early morning
      "31 1 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/change-xapian-database.lock '${pkgPath}/script/compact-xapian-database production' || echo 'stalled?'"
      "0 0 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/delete-expired-embargoes.lock ${pkgPath}/script/delete-expired-embargoes || echo 'stalled?'"
      "23 4 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/delete-old-things.lock ${pkgPath}/script/delete-old-things || echo 'stalled?'"
      "0 5 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/update-overdue-info-request-events.lock ${pkgPath}/script/update-overdue-info-request-events || echo 'stalled?'"
      "0 6 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/alert-overdue-requests.lock ${pkgPath}/script/alert-overdue-requests || echo 'stalled?'"
      "0 7 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/alert-new-response-reminders.lock ${pkgPath}/script/alert-new-response-reminders || echo 'stalled?'"
      "0 7 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/alert-survey.lock ${pkgPath}/script/alert-survey || echo 'stalled?'"
      "0 8 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/alert-not-clarified-request.lock ${pkgPath}/script/alert-not-clarified-request || echo 'stalled?'"
      "0 9 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/alert-embargoes-expiring.lock ${pkgPath}/script/alert-embargoes-expiring || echo 'stalled?'"
      "0 10 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/update-expiring-embargo-info-request-events.lock ${pkgPath}/script/update-expiring-embargo-info-request-events || echo 'stalled?'"
      "0 12 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/alert-embargoes-expired.lock ${pkgPath}/script/alert-embargoes-expired || echo 'stalled?'"
      "2 4 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/check-recent-requests-sent.lock ${pkgPath}/script/check-recent-requests-sent || echo 'stalled?'"
      "45 3 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/stop-new-responses-on-old-requests.lock ${pkgPath}/script/stop-new-responses-on-old-requests || echo 'stalled?'"
      "55 4 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/update-public-body-stats.lock ${pkgPath}/script/update-public-body-stats || echo 'stalled?'"
      "0 6 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/send-webhook-digest.lock ${pkgPath}/script/send-webhook-digest || echo 'stalled?'"
      "30 4 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/storage-raw-emails.lock 'rails --quiet storage:raw_emails:mirror storage:raw_emails:promote storage:raw_emails:unlink' || echo 'stalled?'"
      "30 5 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/storage-attachments.lock 'rails --quiet storage:attachments:mirror storage:attachments:promote storage:attachments:unlink' || echo 'stalled?'"

      # Once a day on all servers
      "43 2 * * * ${cfg.user} ${pkgPath}/script/request-creation-graph"
      "48 2 * * * ${cfg.user} ${pkgPath}/script/user-use-graph"
      "40 2 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/users-signins-purge.lock 'rails users:sign_ins:purge' || echo 'stalled?'"
      "50 2 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/users-purge-limited.lock 'rails --quiet users:purge_limited' || echo 'stalled?'"
      "53 2 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/users-destroy-dormant.lock 'rails --quiet users:destroy_unused' || echo 'stalled?'"
      "38 2 * * * ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/public-body-export.lock 'rails public_body:export' || echo 'stalled?'"

      # Once a week (very early Monday morning)
      "54 2 * * 1 ${cfg.user} ${pkgPath}/script/cleanup-holding-pen"

      # Once a week (early Monday morning)
      "37 8 * * 1 ${cfg.user} ${pkgPath}/commonlib/bin/run-with-lockfile.sh -n ${cfg.dataDir}/send-pro-metrics-report.lock ${pkgPath}/script/send-pro-metrics-report || echo 'stalled?'"

      # Once a week (on a Wednesday evening)
      # not needed on nixos, as we use the geoip service which does this already
      # "42 23 * * 3 ${cfg.user} ${pkgPath}/script/download-geoip-data"

      # Once a year :)
      "0 0 1 11 * ${cfg.user} ${pkgPath}/script/send-public-holiday-reminder"
    ];
  };
}

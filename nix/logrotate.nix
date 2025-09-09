{
  config,
  lib,
  pkgPath,
  ...
}:
let
  cfg = config.services.alaveteli;
in
{
  services.logrotate = {
    enable = true;
    configFile = pkgs.writeText "logrotate.conf" ''
      /var/log/syslog
      {
              rotate 180
              daily
              missingok
              notifempty
              delaycompress
              compress
              postrotate
                      /usr/lib/rsyslog/rsyslog-rotate
              endscript
      }

      /var/log/daemon.log
      /var/log/kern.log
      /var/log/auth.log
      /var/log/user.log
      /var/log/lpr.log
      /var/log/cron.log
      /var/log/debug
      /var/log/messages
      {
              rotate 26
              weekly
              missingok
              notifempty
              compress
              delaycompress
              sharedscripts
              postrotate
                      /usr/lib/rsyslog/rsyslog-rotate
              endscript
      }
    '';
  };
}

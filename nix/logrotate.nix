{
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
in
{
  # /var/log/mail is 0755 postfix:postfix
  # use rsyslogd to log from postfix as some errors cannot be
  # logged directly by postlogd (see
  # https://www.postfix.org/MAILLOG_README.html)
  services.rsyslogd = {
    enable = true;
    defaultConfig = ''
      mail.*                  -/var/log/mail/mail.log
      mail.err                 /var/log/mail/mail.err
    '';
  };

  services.logrotate = {
    enable = true;
    configFile = pkgs.writeText "logrotate.conf" ''
      /var/log/mail/mail.log
      {
          rotate 180
          daily
          dateext
          missingok
          notifempty
          compress
          delaycompress
          sharedscripts
          # alaveteli load-mail-server-logs cron job needs to read postfix logs
          create 0640 root alaveteli
          postrotate
                  systemctl kill --kill-whom=main --signal=SIGHUP syslog.service > /dev/null 2>&1 || true
                  systemctl reload postfix.service > /dev/null 2>&1 || true
          endscript
      }
      ${cfg.dataDir}/log/*.log
      {
          rotate 180
          size 10M
          daily
          dateext
          missingok
          notifempty
          compress
          delaycompress
          su alaveteli alaveteli
      }
    '';
  };
}

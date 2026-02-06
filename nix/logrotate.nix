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
      local5.*                -/var/log/dovecot/dovecot.log
      local5.warning;local5.error;local5.crit   -/var/log/dovecot/dovecot-errors.log
    '';
  };

  services.logrotate = {
    enable = true;
    configFile = pkgs.writeText "logrotate.conf" ''
      /var/log/dovecot.log {
        daily
        rotate 180
        missingok
        notifempty
        compress
        delaycompress
        sharedscripts
        postrotate
            doveadm log reopen
        endscript
      }
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
      /var/log/nginx/*.log
      {
          rotate 180
          daily
          dateext
          missingok
          notifempty
          compress
          delaycompress
          sharedscripts
          postrotate
                  systemctl kill --kill-whom=main --signal=SIGHUP syslog.service > /dev/null 2>&1 || true
                  [ ! -f /var/run/nginx/nginx.pid ] || kill -USR1 `cat /var/run/nginx/nginx.pid`
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
          copytruncate
          su alaveteli alaveteli
      }
    '';
  };
}

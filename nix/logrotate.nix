{
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.alaveteli;
in
{
  # TODO: easier to set maillog_xxx in postfix instead?
  # this seems to have brought in a ton of dependencies
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
          postrotate
                  reload rsyslog >/dev/null 2>&1 || true
                  reload postfix >/dev/null 2>&1 || true
          endscript
      }
    '';
  };
}

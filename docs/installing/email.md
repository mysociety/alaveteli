---
layout: page
title: Installing MTA
---

# Installing the MTA

<p class="lead">
  Alaveteli sends and receives email. You'll need to set up your Mail
  Transfer Agent (MTA) to handle this properly. We've got examples
  here for both postfix and exim4, two of the most popular MTAs.
</p>

<div class="attention-box">
 <ul>
 <li>Commands in this guide will require root privileges</li>
 <li>Commands are intended to be run via the terminal or over ssh</li>
 </ul>
</div>


Make sure you follow the correct instructions for the specific MTA you're using:

* [postfix](#example-setup-on-postfix)
* [exim4](#example-setup-on-exim4)

## Example setup on postfix

This section shows an example of how to set up your MTA if you're using
**postfix** (running on Ubuntu). See the example for
[exim4](#example-setup-on-exim4) if you're using that instead of postfix.

### Instructions

For example, with:

    ALAVETELI_HOME=/path/to/alaveteli/software
    ALAVETELI_USER=www-data

In `/etc/postfix/master.cf`:

    alaveteli unix  - n n - 50 pipe
      flags=R user=ALAVETELI_USER argv=ALAVETELI_HOME/script/mailin

The user ALAVETELI_USER should have write permissions on ALAVETELI_HOME.

In `/etc/postfix/main.cf`:

    virtual_alias_maps = regexp:/etc/postfix/regexp

And, assuming you set
[`INCOMING_EMAIL_PREFIX`]({{ site.baseurl }}docs/customising/config/#incoming_email_prefix)
in `config/general` to "foi+", create `/etc/postfix/regexp` with the following
content:

    /^foi.*/  alaveteli

You should also configure postfix to discard any messages sent to the
[`BLACKHOLE_PREFIX`]({{ site.baseurl }}docs/customising/config/#blackhole_prefix)
address, whose default value is `do-not-reply-to-this-address`. For example, add the
following to `/etc/aliases`:

    # We use this for envelope from for some messages where
    # we don't care about delivery
    do-not-reply-to-this-address:        :blackhole:

### Logging

For the postfix logs to be succesfully read by the script `load-mail-server-logs`, they need
to be log rotated with a date in the filename. Since that will create a lot of rotated log
files (one for each day), it's good to have them in their own directory. For example (on Ubuntu),
in `/etc/rsyslog.d/50-default.conf` set:

    mail.*                  -/var/log/mail/mail.log

And also edit `/etc/logrotate.d/rsyslog`:

    /var/log/mail/mail.log
    {
          rotate 30
          daily
          dateext
          missingok
          notifempty
          compress
          delaycompress
          sharedscripts
          postrotate
                  reload rsyslog >/dev/null 2>&1 || true
          endscript
    }

You'll also need to tell Alaveteli where the log files are stored and that they're in postfix
format. Update
[`MTA_LOG_PATH`]({{ site.baseurl }}docs/customising/config/#mta_log_path) and
[`MTA_LOG_TYPE`]({{ site.baseurl }}docs/customising/config/#mta_log_type) in `config/general.yml` with:

    MTA_LOG_PATH: '/var/log/mail/mail.log-*'
    MTA_LOG_TYPE: "postfix"

### Troubleshooting (postfix)

To test mail delivery, run:

    $ /usr/sbin/sendmail -bv foi+requrest-1234@localhost

This tells you if sending the emails to `foi\+.*localhost` is working.


## Example setup on exim4

This section shows an example of how to set up your MTA if you're using
**exim4**. See the example for
[postfix](#example-setup-on-postfix) if you're using that instead of exim4.


### Install exim4

Install exim4:

     apt-get install exim4


### Configure exim4

#### Set up exim to receive mail from other servers

Edit `/etc/exim4/update-exim4.conf.conf`. Set the following settings (use your hostname, not `example.com`):

    dc_eximconfig_configtype='internet'
    dc_other_hostnames='example.com'
    dc_local_interfaces='0.0.0.0 ; ::1'
    dc_use_split_config='true'

This final line tells exim to use the files in `/etc/exim4/conf.d` to configure itself.


    ALAVETELI_HOME=/var/www/alaveteli
    ALAVETELI_USER=alaveteli
    log_file_path=/var/log/exim4/exim-%slog-%D
    MAIN_LOG_SELECTOR==+all -retry_defer
    extract_addresses_remove_arguments=false

The `ALAVETELI_HOME` variable should be set to the directory where Alaveteli is installed. `ALAVETELI_USER` should be the Unix user that is going to run your site. They should have write permissions on `ALAVETELI_HOME`.

The name and location of the log files created by Exim must match what the
`load-mail-server-logs` script expects, which is why you must provide the
`log_file_path` setting.

The `check-recent-requests-sent` scripts expects the logs to contain the
`from=<...>` envelope information, so we make the logs more verbose with
`log_selector`. The ALAVETELI_USER may need to also need to be added to the
`trusted_users` list in your Exim config in order to set the return path on
outgoing mail, depending on your setup.

In `/etc/exim4/conf.d/router/04_alaveteli`:

    alaveteli_request:
       debug_print = "R: alaveteli for $local_part@$domain"
       driver = redirect
       data = ${lookup{$local_part}wildlsearch{ALAVETELI_HOME/config/aliases}}
       pipe_transport = alaveteli_mailin_transport

In `/etc/exim4/conf.d/transport/04_alaveteli`:

    alaveteli_mailin_transport:
       driver = pipe
       command = $address_pipe ${lc:$local_part}
       current_directory = ALAVETELI_HOME
       home_directory = ALAVETELI_HOME
       user = ALAVETELI_USER
       group = ALAVETELI_USER

And, assuming you set
[`INCOMING_EMAIL_PREFIX`]({{ site.baseurl }}docs/customising/config/#incoming_email_prefix)
in your config at `config/general.yml` to "foi+", create `config/aliases` with the following
content:

    ^foi\\+.*: |/var/www/alaveteli/script/mailin
#### Set up your contact email recipient groups

To set up recipient groups for the `team@` and `user-support@` email addresses at your domain, add alias records for them in `/var/www/alaveteli/config/etc/aliases`

    team: user@example.com, otheruser@example.com
    user-support: team

You should also configure exim to discard any messages sent to the
[`BLACKHOLE_PREFIX`]({{ site.baseurl }}docs/customising/config/#blackhole_prefix)
address, whose default value is
`do-not-reply-to-this-address`. For example, add the following to
`config/aliases`:

    # We use this for envelope from for some messages where we don't care about delivery
    do-not-reply-to-this-address:        :blackhole:

If you want to make use of the automatic bounce-message handling, then set the
[`TRACK_SENDER_EMAIL`]({{ site.baseurl }}docs/customising/config/#track_sender_email)
address to be filtered through
`script/handle-mail-replies`. Messages that are not bounces or
out-of-office autoreplies will be forwarded to
[`FORWARD_NONBOUNCE_RESPONSES_TO`]({{ site.baseurl }}docs/customising/config/#forward_nonbounce_responses_to).
For example, you could add the following to `config/aliases`:

    real_team: [a list of people on the team]
    team:     |/var/www/alaveteli/script/handle-mail-replies

In your Alaveteli `config/general.yml` file you would have (replacing `example.com` with your domain):

    FORWARD_NONBOUNCE_RESPONSES_TO: 'real_team@example.com'

Finally, make sure you have `dc_use_split_config='true'` in
`/etc/exim4/update-exim4.conf.conf` so that exim uses the files in `/etc/exim4/conf.d` to configure itself, and execute the command
`update-exim4.conf`.

Note that if the file `/etc/exim4/exim4.conf` exists then `update-exim4.conf`
will silently do nothing. Some distributions include this file. If
yours does, you will need to rename it before running `update-exim4.conf`.

(You may also want to set `dc_eximconfig_configtype='internet'`,
`dc_local_interfaces='0.0.0.0 ; ::1'`, and
`dc_other_hostnames='example.com'` - using your domain name, not `example.com`).


### Troubleshooting (exim)

To test mail delivery, as a privileged user run:

    exim4 -bt foi+request-1234@example.com

replacing `example.com` with your domain name. This should tell you which routers are being processed.  You should
see something like:

    $ exim4 -bt foi+request-1234@localhost
    R: alaveteli for foi+request-1234@example.com
    foi+request-1234@example.com -> |/var/www/alaveteli/script/mailin
      transport = alaveteli_mailin_transport

This tells you that the routing part (making emails to
`foi\+.*@example.com` be forwarded to Alaveteli's `mailin` script) is
working.

There is a great
[Exim Cheatsheet](http://bradthemad.org/tech/notes/exim_cheatsheet.php)
online that you may find useful.

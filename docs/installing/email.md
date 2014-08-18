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

#### Define general variables and logging settings

Create `/etc/exim4/conf.d/main/04_alaveteli_options` with the command:

    cat > /etc/exim4/conf.d/main/04_alaveteli_options <<'EOF'
    ALAVETELI_HOME=/var/www/alaveteli
    ALAVETELI_USER=alaveteli
    log_file_path=/var/log/exim4/exim-%slog-%D
    MAIN_LOG_SELECTOR==+all -retry_defer
    extract_addresses_remove_arguments=false
    EOF

This sets up `ALAVETELI_HOME` and `ALAVETELI_USER` for use in other config files, and sets up logging. The `ALAVETELI_HOME` variable should be set to the directory where Alaveteli is installed. `ALAVETELI_USER` should be the Unix user that is going to run your site. They should have write permissions on `ALAVETELI_HOME`.

Note that if you are editing an existing exim config that restricts the `untrusted_set_sender` option, you will need also to add `ALAVETELI_USER` to the `trusted_users` list in order to allow them to set the return path on outgoing mail. This option is in `/etx/exim4/conf.d/main/02_exim4-config_options` in a split config.

The name and location of the log files created by Exim must match what the
`load-mail-server-logs` script expects, which is why you must provide the
`log_file_path` setting.

The `check-recent-requests-sent` scripts expects the logs to contain the
`from=<...>` envelope information, so we make the logs more verbose with
`MAIN_LOG_SELECTOR`.

Setting `extract_addresses_remove_arguments` to `false` gets exim to treat the `-t` command line option that the `mail` gem uses when specifying delivery addresses on the command line as specifying that the addresses should be added, not removed. See [this `mail` issue](https://github.com/mikel/mail/issues/70) for more details.

#### Pipe incoming mail for requests from Exim to Alaveteli

In this section, we'll add config to pipe incoming mail for special
Alaveteli addresses into Alaveteli, and also send them to a local backup
mailbox, just in case. Create the `backupfoi` UNIX user, and then create `/etc/exim4/conf.d/router/04_alaveteli` to specify an exim `router` for special Alaveteli addresses, which will route messages into Alaveteli using a local pipe transport:

    cat > /etc/exim4/conf.d/router/04_alaveteli <<'EOF'
    alaveteli_request:
       debug_print = "R: alaveteli for $local_part@$domain"
       driver = redirect
       data = ${lookup{$local_part}wildlsearch{ALAVETELI_HOME/config/aliases}}
       pipe_transport = alaveteli_mailin_transport
    EOF

Create `/etc/exim4/conf.d/transport/04_alaveteli`, which sets the properties of the pipe `transport` that will deliver mail to Alaveteli:

    cat > /etc/exim4/conf.d/transport/04_alaveteli <<'EOF'
    alaveteli_mailin_transport:
       driver = pipe
       command = $address_pipe ${lc:$local_part}
       current_directory = ALAVETELI_HOME
       home_directory = ALAVETELI_HOME
       user = ALAVETELI_USER
       group = ALAVETELI_USER
    EOF

And, assuming you set [`INCOMING_EMAIL_PREFIX`]({{ site.baseurl }}docs/customising/config/#incoming_email_prefix) in your config at
`config/general.yml` to "foi+", create `config/aliases` with the
following command. This defines the special addresses that the `router`
and `transport` will apply to with a regular expression. It also defines
the pipe command to be used:

    cat > /var/www/alaveteli/config/aliases <<'EOF'
    ^foi\\+.*: "|/var/www/alaveteli/script/mailin", backupfoi
    EOF

That's assuming that Alaveteli is running from `/var/www/alaveteli`. If it isn't, substitute the path it is running from.

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

#### Filter incoming messages to admin addresses

As described in ['Other mail']({{site.baseurl}}docs/installing/email#other-mail) you can make use of the script that filters mail to [`TRACK_SENDER_EMAIL`]({{site.baseurl}}docs/customising/config/#track_sender_email) and [`CONTACT_EMAIL`]({{site.baseurl}}docs/customising/config/#contact_email) for bounce messages before delivering it to your admin team.
To do this, for a `general.yml` file
that sets those addresses to `user-support@example.com` and
[`FORWARD_NONBOUNCE_RESPONSES_TO`]({{site.baseurl}}docs/customising/config/#forward_nonbounce_responses_to) to
`team@example.com`, update the `user-support` line in  `/var/www/alaveteli/config/aliases`:

    user-support:     |/var/www/alaveteli/script/handle-mail-replies

#### Making the changes live in exim

Finally, execute the command:

    update-exim4.conf
    service exim4 restart

Note that if the file `/etc/exim4/exim4.conf` exists then `update-exim4.conf`
will silently do nothing. Some distributions include this file. If
yours does, you will need to remove or rename it before running `update-exim4.conf`.


#### Troubleshooting (exim)

To test mail delivery, as a privileged user run:

    exim4 -bt foi+request-1234@example.com

replacing `example.com` with your domain name. This should tell you which routers are being processed.  You should
see something like:

    $ exim4 -bt foi+request-1234@example.com
    R: alaveteli for foi+request-1234@example.com
    foi+request-1234@example.com -> |/var/www/alaveteli/script/mailin
      transport = alaveteli_mailin_transport
    R: alaveteli for backupfoi@your.machine.name
    R: system_aliases for backupfoi@your.machine.name
    R: userforward for backupfoi@your.machine.name
    R: procmail for backupfoi@your.machine.name
    R: maildrop for backupfoi@your.machine.name
    R: lowuid_aliases for backupfoi@your.machine.name (UID 1001)
    R: local_user for backupfoi@your.machine.name
    backupfoi@your.machine.name
        <-- foi+request-1234@example.com
      router = local_user, transport = mail_spool

This tells you that the routing part (making emails to
`foi\+.*@example.com` be forwarded to Alaveteli's `mailin` script, and
also sent to the local backup account) is working. You can test bounce
message routing in the same way:

    exim4 -bt user-support@example.com
    R: alaveteli for user-support@example.com
    user-support@example.com -> |/var/www/alaveteli/script/handle-mail-replies
      transport = alaveteli_mailin_transport

There is a great
[Exim Cheatsheet](http://bradthemad.org/tech/notes/exim_cheatsheet.php)
online that you may find useful.

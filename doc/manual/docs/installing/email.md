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

## How Alaveteli handles email

### Request mail

When someone makes a Freedom of Information request to an authority through
Alaveteli, the application sends an email containing the request to the authority.

The email's `reply-to` address is a special one so that any replies to it
can be automatically directed back to Alaveteli, and so that Alaveteli
can tell which request the reply needs to be shown with. This requires
some configuration of the MTA on the server that is running Alaveteli,
so that it will pipe all emails to these special addresses to Alaveteli
to handle, via its `script/mailin` script. The special addresses are of
the form:

    <foi+request-3-691c8388@example.com>

Parts of this address are controlled with options in
`config/general.yml`:

    INCOMING_EMAIL_PREFIX = 'foi+'
    INCOMING_EMAIL_DOMAIN = 'example.com'

If there is some error inside Rails while processing an email,  an exit code `75` is returned to the MTA by the `script/mailin` script. Postfix and Exim (and maybe others) take this  as a signal for the MTA to try again later. Additionally, a stacktrace is emailed to `CONTACT_EMAIL`.

[Production]({{ site.baseurl }}/docs/glossary/#production) installs of Alaveteli should make a backup copy of emails sent to the special addresses. You can configure your chosen MTA to backup these in a separate mailbox.

### Transactional mail

Alaveteli also sends emails to users about their requests – letting them know when someone has replied to them, or prompting them to take further action.

Configure the address that these messages are sent from in the [`CONTACT_EMAIL`]({{site.baseurl}}docs/customising/config/#contact_email) option in `config/general.yml`:

    CONTACT_EMAIL = 'team@example.com'

The address in [`CONTACT_EMAIL`]({{ site.baseurl }}docs/customising/config/#contact_email) is also visible in various places on the site so that users can get in touch with the team that runs the site.

You must configure your MTA to deliver mail sent to these addresses to the administrators of your site so that they can respond to it.

### Tracks mail

Users subscribed to updates from the site – known as `tracks` – receive emails when there is something new of interest to them on the site.

Configure the address that these messages are sent from in the [`TRACK_SENDER_EMAIL`]({{site.baseurl}}docs/customising/config/#track_sender_email) option in `config/general.yml`:

    TRACK_SENDER_EMAIL = 'track@example.com'

### Automatic bounce handling (optional)

As [`CONTACT_EMAIL`]({{ site.baseurl }}docs/customising/config/#contact_email) and [`TRACK_SENDER_EMAIL`]({{site.baseurl}}docs/customising/config/#track_sender_email) appear in the `From:` header of emails sent from Alaveteli, they sometimes receive reply emails, including <a href="{{ site.baseurl }}docs/glossary/#bounce-message">bounce messages</a> and ‘out of office’ notifications.

Alaveteli provides a script (`script/handle-mail-replies`) that handles bounce messages and ‘out of office’ notifications and forwards genuine mails to your administrators.

It also prevents further track emails being sent to a user email address that appears to have a permanent delivery problem.

To make use of automatic bounce-message handling, set [`TRACK_SENDER_EMAIL`]({{ site.baseurl }}docs/customising/config/#track_sender_email) and [`CONTACT_EMAIL`]({{ site.baseurl }}docs/customising/config/#contact_email) to an address that you will filter through `script/handle-mail-replies`. Messages that are not bounces or out-of-office autoreplies will be forwarded to [`FORWARD_NONBOUNCE_RESPONSES_TO`]({{ site.baseurl }}docs/customising/config/#forward_nonbounce_responses_to), which you should set to a mail alias that points at your list of site administrators.

See the MTA-specific instructions for how to do this for [exim]({{ site.baseurl }}docs/installing/email#filter-incoming-messages-to-admin-addresses) and [postfix]({{ site.baseurl }}docs/installing/email#filter-incoming-messages-to-site-admin-addresses).

Note that this bounce handling is not applied to request email
addresses; any bounce messages from authorities will be added to the
request page so that the user can see what has happened and ask site
admins for help redelivering the request if necessary.


---

Make sure you follow the correct instructions for the specific MTA you're using:

* [postfix](#example-setup-on-postfix)
* [exim4](#example-setup-on-exim4)

## Example setup on postfix

This section shows an example of how to set up your MTA if you're using
**postfix**. See the example for
[exim4](#example-setup-on-exim4) if you're using that instead of postfix.

### Install postfix

    # Install debconf so we can configure non-interactively
    apt-get -qq install -y debconf >/dev/null

    # Set the default configuration 'Internet Site'
    echo postfix postfix/main_mailer_type select 'Internet Site' | debconf-set-selections

    # Set your hostname (change example.com to your hostname)
    echo postfix postfix/mail_name string "example.com" | debconf-set-selections

    # Install postfix
    DEBIAN_FRONTEND=noninteractive apt-get -qq -y install postfix >/dev/null

### Configure postfix


#### Pipe incoming mail for requests into Alaveteli

If the Unix user that is going to
run your site is `alaveteli`, and the directory where Alaveteli is installed is
`/var/www/alaveteli`, add the following line to
`/etc/postfix/master.cf`:

    alaveteli unix  - n n - 50 pipe
      flags=R user=alaveteli argv=/var/www/alaveteli/script/mailin

The Unix user should have write permissions on the directory where Alaveteli is installed.

In `/etc/postfix/main.cf`, add:

    transport_maps = regexp:/etc/postfix/transports
    local_recipient_maps = proxy:unix:passwd.byname regexp:/etc/postfix/recipients

This tells postfix to accept messages for local delivery where
recipients are either defined by a regular expression in
`/etc/postfix/transports`, are local UNIX accounts or are local aliases
specified as regular expressions in `/etc/postfix/recipients`. Also
update the `mydestination` line (which determines what domains this
machine will deliver locally) - add your domain, not `example.com`, to
the beginning of the list:

    mydestination = example.com, localhost.localdomain, localhost

And, assuming you set
[`INCOMING_EMAIL_PREFIX`]({{ site.baseurl }}docs/customising/config/#incoming_email_prefix)
in `config/general` to "foi+", create `/etc/postfix/transports` with the following
command:

    cat > /etc/postfix/transports <<EOF
    /^foi.*/                alaveteli
    EOF

This means that all incoming mail that starts `foi+` will be piped to `/var/www/alaveteli/script/mailin` as specified in `/etc/postfix/master.cf` at the start of this section.

You can copy all incoming mail to Alaveteli to a backup account to a separate mailbox, just in case. Create a UNIX user `backupfoi`, and add the following line to
`/etc/postfix/main.cf`

    recipient_bcc_maps = regexp:/etc/postfix/recipient_bcc

Create `/etc/postfix/recipient_bcc` with the following command:

    cat > /etc/postfix/recipient_bcc <<EOF
    /^foi.*/                backupfoi
    EOF


#### Define the valid recipients for your domain

Create `/etc/postfix/recipients` with the following command:

    cat > /etc/postfix/recipients <<EOF
    /^foi.*/                this-is-ignored
    /^postmaster@/          this-is-ignored
    /^user-support@/        this-is-ignored
    /^team@/                this-is-ignored
    EOF

The left-hand column of this file specifies regular expressions that
define addresses that mail will be accepted for. The values on the
right-hand side are ignored by postfix. Here we allow postfix to accept
mails to special Alaveteli addresses, and `postmaster@example.com`,
`user-support@example.com` and `team@example.com`.

#### Set up contact email recipient groups

To set up recipient groups for the `postmaster@`, `team@` and `user-support@` email addresses at your domain, add alias records for them in `/etc/aliases`:

    team: user@example.com, otheruser@example.com
    user-support: team

You should also configure postfix to discard any messages sent to the [`BLACKHOLE_PREFIX`]({{ site.baseurl }}docs/customising/config/#blackhole_prefix) address, whose default value is `do-not-reply-to-this-address`. For example, add the following to `/etc/aliases`:

        # We use this for envelope from for some messages where
        # we don't care about delivery
        do-not-reply-to-this-address:        /dev/null

#### Filter incoming messages to site admin addresses

As described in ['Other
mail']({{site.baseurl}}docs/installing/email#other-mail) you can make
use of the script that filters mail to
[`TRACK_SENDER_EMAIL`]({{site.baseurl}}docs/customising/config/#track_sender_email)
and [`CONTACT_EMAIL`]({{site.baseurl}}docs/customising/config/#contact_email) for bounce messages before
delivering it to your admin team. To do this, for a `general.yml` file
that sets those addresses to `user-support@example.com` and
[`FORWARD_NONBOUNCE_RESPONSES_TO`]({{site.baseurl}}docs/customising/config/#forward_nonbounce_responses_to) to
`team@example.com`, add a new line to `/etc/postfix/master.cf`:

        alaveteli_replies unix  - n n - 50 pipe
          flags=R user=alaveteli argv=/var/www/alaveteli/script/handle-mail-replies

making sure to replace `/var/www/alaveteli` with the correct path to
alaveteli if you're not running it from `/var/www/alaveteli`. Next, add
a line to `/etc/postfix/transports`:

    /^user-support@*/                alaveteli_replies

Finally, edit `/etc/aliases` to remove `user-support`:

    team: user@example.com, otheruser@example.com


#### Logging

For the postfix logs to be successfully read by the script
`load-mail-server-logs`, they need to be log rotated with a date in the
filename. Since that will create a lot of rotated log files (one for
each day), it's good to have them in their own directory.

You'll also need to tell Alaveteli where the log files are stored and that they're in postfix
format. Update
[`MTA_LOG_PATH`]({{ site.baseurl }}docs/customising/config/#mta_log_path) and
[`MTA_LOG_TYPE`]({{ site.baseurl }}docs/customising/config/#mta_log_type) in `config/general.yml` with:

    MTA_LOG_PATH: '/var/log/mail/mail.log-*'
    MTA_LOG_TYPE: "postfix"

##### Debian

In `/etc/rsyslog.conf`, set:

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

##### Ubuntu

In `/etc/rsyslog.d/50-default.conf` set:

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


#### Making the changes live

As the root user, make all these changes live with the following commands:

    service rsyslog restart

    newaliases
    postmap /etc/postfix/transports
    postmap /etc/postfix/recipients
    postmap /etc/postfix/recipient_bcc
    postfix reload

#### Troubleshooting (postfix)

To test mail delivery, run:

    $ /usr/sbin/sendmail -bv foi+request-1234@example.com

Make sure to replace `example.com` with your domain. This command tells
you if sending the emails to `foi\+.*example.com` and the backup account
is working (it doesn't actually send any mail). If it is working, you
should receive a delivery report email, with text like:

    <foi+request-1234@example.com>: delivery via alaveteli:
delivers to command: /var/www/alaveteli/script/mailin
    <backupfoi@local.machine.name>: delivery via local: delivers to  mailbox

You can also test the other aliases you have set up for your domain in
this section to check that they will deliver mail as you expect. For
example, you can test bounce message routing in the same way - the text
of this delivery report mail should read something like:

    <user-support@example.com>: delivery via alaveteli_replies: delivers to command: /var/www/alaveteli/script/handle-mail-replies


Note that you may need to install the `mailutils` package to read the
delivery report email using the `mail` command on a new server:

    apt-get install mailutils


## Example setup on exim4

This section shows an example of how to set up your MTA if you're using
**exim4**. See the example for
[postfix](#example-setup-on-postfix) if you're using that instead of exim4.


### Instructions

We suggest you add the following to your exim configuration.

In `/etc/exim4/conf.d/main/04_alaveteli_options`, set:

    ALAVETELI_HOME=/path/to/alaveteli/software
    ALAVETELI_USER=www-data
    log_file_path=/var/log/exim4/exim-%slog-%D
    MAIN_LOG_SELECTOR==+all -retry_defer
    extract_addresses_remove_arguments=false

The user ALAVETELI_USER should have write permissions on ALAVETELI_HOME.

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

    ^foi\\+.*: |/path/to/alaveteli/software/script/mailin

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
For example, in WhatDoTheyKnow the
configuration looks like this:

    raw_team: [a list of people on the team]
    team:     |/path/to/alaveteli/software/script/handle-mail-replies

with `FORWARD_NONBOUNCE_RESPONSES_TO`: 'raw_team@whatdotheyknow.com'`

Finally, make sure you have `dc_use_split_config='true'` in
`/etc/exim4/update-exim4.conf.conf`, and execute the command
`update-exim4.conf`.

Note that if the file `/etc/exim4/exim4.conf` exists then `update-exim4.conf`
will silently do nothing. Some distributions include this file. If
yours does, you will need to rename it before running `update-exim4.conf`.

(You may also want to set `dc_eximconfig_configtype='internet'`,
`dc_local_interfaces='0.0.0.0 ; ::1'`, and
`dc_other_hostnames='<your-host-name>'`).

### Troubleshooting (exim)

To test mail delivery, run:

    exim -bt foi+request-1234@localhost

This should tell you which routers are being processed.  You should
see something like:

    $ exim -bt foi+request-1234@localhost
    R: alaveteli pipe for snafflerequest-234@localhost
    snafflerequest-234@localhost -> |/home/alaveteli/alaveteli/script/mailin
    transport = alaveteli_mailin_transport

This tells you that the routing part (making emails to
`foi\+.*@localhost` be forwarded to Alaveteli's `mailin` script) is
working.

There is a great
[Exim Cheatsheet](http://bradthemad.org/tech/notes/exim_cheatsheet.php)
online that you may find useful.

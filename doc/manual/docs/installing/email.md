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

[Production]({{ page.baseurl }}//docs/glossary/#production) installs of Alaveteli should make a backup copy of emails sent to the special addresses. You can configure your chosen MTA to backup these in a separate mailbox.

### Transactional mail

Alaveteli also sends emails to users about their requests – letting them know when someone has replied to them, or prompting them to take further action.

Configure the address that these messages are sent from in the [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email) option in `config/general.yml`:

    CONTACT_EMAIL = 'team@example.com'

The address in [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email) is also visible in various places on the site so that users can get in touch with the team that runs the site.

You must configure your MTA to deliver mail sent to these addresses to the administrators of your site so that they can respond to it.

### Tracks mail

Users subscribed to updates from the site – known as `tracks` – receive emails when there is something new of interest to them on the site.

Configure the address that these messages are sent from in the [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email) option in `config/general.yml`:

    TRACK_SENDER_EMAIL = 'track@example.com'

### Automatic bounce handling (optional)

As [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email) and [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email) appear in the `From:` header of emails sent from Alaveteli, they sometimes receive reply emails, including <a href="{{ page.baseurl }}/docs/glossary/#bounce-message">bounce messages</a> and ‘out of office’ notifications.

Alaveteli provides a script (`script/handle-mail-replies`) that handles bounce messages and ‘out of office’ notifications and forwards genuine mails to your administrators.

It also prevents further track emails being sent to a user email address that appears to have a permanent delivery problem.

To make use of automatic bounce-message handling, set [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email) and [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email) to an address that you will filter through `script/handle-mail-replies`. Messages that are not bounces or out-of-office autoreplies will be forwarded to [`FORWARD_NONBOUNCE_RESPONSES_TO`]({{ page.baseurl }}/docs/customising/config/#forward_nonbounce_responses_to), which you should set to a mail alias that points at your list of site administrators.

See the MTA-specific instructions for how to do this for [exim]({{ page.baseurl }}/docs/installing/email#filter-incoming-messages-to-admin-addresses) and [postfix]({{ page.baseurl }}/docs/installing/email#filter-incoming-messages-to-site-admin-addresses).

_Note:_ Bounce handling is not applied to [request emails]({{ page.baseurl }}/docs/installing/email#request-mail). Bounce messages from authorities get added to the request page so that the user can see what has happened. Users can ask site admins for help redelivering the request if necessary.


---

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
`/var/www/alaveteli`, create the pipe that will receive request mail:

    cat >> /etc/postfix/master.cf <<EOF
    alaveteli unix  - n n - 50 pipe
      flags=R user=alaveteli argv=/var/www/alaveteli/script/mailin
    EOF

The Unix user should have write permissions on the directory where Alaveteli is installed.

Configure postfix to accept messages for local delivery where
recipients are:

  - defined by a regular expression in `/etc/postfix/transports`
  - local UNIX accounts
  - local aliases specified as regular expressions in `/etc/postfix/recipients`

<!-- Comment to enable markdown to render code fence under list -->

    cat >> /etc/postfix/main.cf <<EOF
    transport_maps = regexp:/etc/postfix/transports
    local_recipient_maps = proxy:unix:passwd.byname regexp:/etc/postfix/recipients
    EOF

In `/etc/postfix/main.cf` update the `mydestination` line (which determines what domains this machine will deliver locally). Add your domain, not `example.com`, to the beginning of the list:

    mydestination = example.com, localhost.localdomain, localhost

<div class="attention-box">
This guide assumes you have set <a href="{{ page.baseurl }}/docs/customising/config/#incoming_email_prefix"><code>INCOMING_EMAIL_PREFIX</code></a> to <code>foi+</code> in <code>config/general.yml</code>
</div>

Pipe all incoming mail where the `To:` address starts with `foi+` to the `alaveteli` pipe (`/var/www/alaveteli/script/mailin`, as specified in `/etc/postfix/master.cf` at the start of this section):

    cat > /etc/postfix/transports <<EOF
    /^foi.*/                alaveteli
    EOF

#### Backup request mail

You can copy all incoming mail to Alaveteli to a backup account to a separate mailbox, just in case.

Create a UNIX user `backupfoi`

    adduser --quiet --disabled-password \
      --gecos "Alaveteli Mail Backup" backupfoi

Add the following line to `/etc/postfix/main.cf`

    recipient_bcc_maps = regexp:/etc/postfix/recipient_bcc

Configure mail sent to an `foi+` prefixed address to be sent to the backup user:

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

The `@example.com` domain is set in the `mydestination` as above. This should be set to your actual domain.

#### Set up contact email recipient groups

To set up recipient groups for the `postmaster@`, `team@` and `user-support@` email addresses at your domain, add alias records for them in `/etc/aliases`:

    cat >> /etc/aliases <<EOF
    team: user@example.com, otheruser@example.com
    user-support: team
    EOF

#### Discard unwanted incoming email

Configure postfix to discard any messages sent to the [`BLACKHOLE_PREFIX`]({{ page.baseurl }}/docs/customising/config/#blackhole_prefix) address, whose default value is `do-not-reply-to-this-address`:

    cat >> /etc/aliases <<EOF
    # We use this for envelope from for some messages where
    # we don't care about delivery
    do-not-reply-to-this-address:        /dev/null
    EOF

If you have set [`BLACKHOLE_PREFIX`]({{ page.baseurl }}/docs/customising/config/#blackhole_prefix) address, replace `do-not-reply-to-this-address` with the address you have configured.

#### Filter incoming messages to site admin addresses

You can make use of Alaveteli's [automatic bounce handling]({{ page.baseurl }}/docs/installing/email/#automatic-bounce-handling-optional) to filter bounces sent to [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email)
and [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email).


<div class="attention-box">
This guide assumes you have set the following in <code>config/general.yml</code>:

  <ul>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#contact_email">CONTACT_EMAIL</a>: <code>user-support@example.com</code></li>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#track_sender_email">TRACK_SENDER_EMAIL</a>: <code>user-support@example.com</code></li>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#forward_nonbounce_responses_to">FORWARD_NONBOUNCE_RESPONSES_TO</a>: <code>team@example.com</code></li>
  </ul>

Change the examples below to the addresses you have configured.
</div>

Create a new pipe to handle replies:

    cat >> /etc/postfix/master.cf <<EOF
    alaveteli_replies unix  - n n - 50 pipe
      flags=R user=alaveteli argv=/var/www/alaveteli/script/handle-mail-replies
    EOF

_Note:_ Replace `/var/www/alaveteli` with the correct path to alaveteli if required.

Pipe mail sent to `user-support@example.com` to the `alaveteli_replies` pipe:

    cat >> /etc/postfix/transports <<EOF
    /^user-support@*/                alaveteli_replies
    EOF

Finally, edit `/etc/aliases` to remove `user-support`:

    team: user@example.com, otheruser@example.com

#### Logging

For the postfix logs to be successfully read by
`script/load-mail-server-logs`, they need to be log rotated with a date in the
filename. Since that will create a lot of rotated log files (one for
each day), it's good to have them in their own directory.

You'll also need to tell Alaveteli where the log files are stored and that they're in postfix
format. Update
[`MTA_LOG_PATH`]({{ page.baseurl }}/docs/customising/config/#mta_log_path) and
[`MTA_LOG_TYPE`]({{ page.baseurl }}/docs/customising/config/#mta_log_type) in `config/general.yml`:

    MTA_LOG_PATH: '/var/log/mail/mail.log-*'
    MTA_LOG_TYPE: "postfix"

Configure postfix to log to its own directory:

##### Debian

In `/etc/rsyslog.conf`, set:

    mail.*                  -/var/log/mail/mail.log


##### Ubuntu

In `/etc/rsyslog.d/50-default.conf` set:

    mail.*                  -/var/log/mail/mail.log

##### Configure logrotate

Configure logrotate to rotate the log files in the required format:

    cat >> /etc/logrotate.d/rsyslog <<EOF
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
    EOF

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

If emails are not being received by your Alaveteli install, we have some
more troubleshooting tips for incoming mail in [general email troubleshooting]({{ page.baseurl }}/docs/installing/email#general-email-troubleshooting).



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

This sets up `ALAVETELI_HOME` and `ALAVETELI_USER` for use in other config files, and sets up logging.

- **`ALAVETELI_HOME`:** set to the directory where Alaveteli is installed.
- **`ALAVETELI_USER`:** should be the Unix user that is going to run your site. They should have write permissions on `ALAVETELI_HOME`.
- **`log_file_path`:** The name and location of the log files created by Exim must match what the `load-mail-server-logs` script expects
- **`MAIN_LOG_SELECTOR`:** The `check-recent-requests-sent` scripts expects the logs to contain the `from=<...>` envelope information, so we make the logs more verbose
- **`extract_addresses_remove_arguments`:** setting to `false` gets exim to treat the `-t` command line option that the `mail` gem uses when specifying delivery addresses on the command line as specifying that the addresses should be added, not removed. See [this `mail` issue](https://github.com/mikel/mail/issues/70) for more details.

<div class="attention-box">
Note: If you are editing an existing exim config rather than creating a new one, check the <code>untrusted_set_sender</code> option in  <code>/etc/exim4/conf.d/main/02_exim4-config_options</code>. By default, untrusted users in exim are only allowed to set an empty envelope sender address, to declare that a message should never generate any bounces. <code>untrusted_set_sender</code> can be set to a list of address patterns, meaning that  untrusted users are allowed to set envelope sender addresses that match any of the patterns in the list. If a pattern list is specified,  you will need also to add <code>ALAVETELI_USER</code> to the <code>MAIN_TRUSTED_USERS</code> list in order to allow them to set the return path on outgoing mail. This option is also in <code>/etc/exim4/conf.d/main/02_exim4-config_options</code> in a split config. Look for the line that begins with <code>MAIN_TRUSTED_USERS</code> - something like:

    <pre><code>MAIN_TRUSTED_USERS = uucp</code></pre>

and add the alaveteli user:

    <pre><code>MAIN_TRUSTED_USERS = uucp : alaveteli</code></pre>

 If <code>untrusted_set_sender</code> is set to <code>*</code>, that means that untrusted users can set envelope sender addresses without restriction, so there's no need to add <code>ALAVETELI_USER</code> to the <code>MAIN_TRUSTED_USERS</code> list.
</div>

#### Pipe incoming mail for requests from Exim to Alaveteli

In this section, we'll add config to pipe incoming mail for special
Alaveteli addresses into Alaveteli, and also send them to a local backup
mailbox.

Create the `backupfoi` UNIX user

    adduser --quiet --disabled-password \
      --gecos "Alaveteli Mail Backup" backupfoi

Specify an exim `router` for special Alaveteli addresses, which will route messages into Alaveteli using a local pipe transport:

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


<div class="attention-box">
  This guide assumes you have set <a href="/docs/customising/config/#incoming_email_prefix"><code>INCOMING_EMAIL_PREFIX</code></a> to <code>foi+</code> in <code>config/general.yml</code>
</div>

Create the `config/aliases` file that the `alaveteli_request` exim `router` sources. This pipes mail from the special address to `script/mailin` and the `backupfoi` user.

    cat > /var/www/alaveteli/config/aliases <<'EOF'
    ^foi\\+.*: "|/var/www/alaveteli/script/mailin", backupfoi
    EOF

_Note:_ Replace `/var/www/alaveteli` with the correct path to alaveteli if required.

#### Set up your contact email recipient groups

To set up recipient groups for the `team@` and `user-support@` email addresses at your domain, add alias records for them in `/var/www/alaveteli/config/aliases`

    cat >> /var/www/alaveteli/config/aliases <<EOF
    team: user@example.com, otheruser@example.com
    user-support: team
    EOF

#### Discard unwanted incoming email

Configure exim to discard any messages sent to the [`BLACKHOLE_PREFIX`]({{ page.baseurl }}/docs/customising/config/#blackhole_prefix) address, whose default value is `do-not-reply-to-this-address`

    cat >> /var/www/alaveteli/config/aliases <<EOF
    # We use this for envelope from for some messages where
    # we don't care about delivery
    do-not-reply-to-this-address:        :blackhole:
    EOF

_Note:_ Replace `/var/www/alaveteli` with the correct path to alaveteli if required.

#### Filter incoming messages to admin addresses

You can make use of Alaveteli's [automatic bounce handling]({{ page.baseurl }}/docs/installing/email/#automatic-bounce-handling-optional) to filter bounces sent to [`TRACK_SENDER_EMAIL`]({{ page.baseurl }}/docs/customising/config/#track_sender_email)
and [`CONTACT_EMAIL`]({{ page.baseurl }}/docs/customising/config/#contact_email).

<div class="attention-box">
This guide assumes you have set the following in <code>config/general.yml</code>:

  <ul>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#contact_email">CONTACT_EMAIL</a>: <code>user-support@example.com</code></li>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#track_sender_email">TRACK_SENDER_EMAIL</a>: <code>user-support@example.com</code></li>
    <li><a href="{{ page.baseurl }}/docs/customising/config/#forward_nonbounce_responses_to">FORWARD_NONBOUNCE_RESPONSES_TO</a>: <code>team@example.com</code></li>
  </ul>

Change the examples below to the addresses you have configured.
</div>

Change the `user-support` line in `/var/www/alaveteli/config/aliases`:

    user-support:     |/var/www/alaveteli/script/handle-mail-replies

#### Logging

You’ll need to tell Alaveteli where the log files are stored and that they’re in exim format. Update [`MTA_LOG_PATH`]({{ page.baseurl }}/docs/customising/config/#mta_log_path) and [`MTA_LOG_TYPE`]({{ page.baseurl }}/docs/customising/config/#mta_log_type) in `config/general.yml`:

    MTA_LOG_PATH: '/var/log/exim4/exim-mainlog-*'
    MTA_LOG_TYPE: 'exim'


#### Making the changes live in exim

Finally, execute the commands:

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

If emails are not being received by your Alaveteli install, we have some
more troubleshooting tips for incoming mail in the next section. There is also a
great [Exim
Cheatsheet](http://bradthemad.org/tech/notes/exim_cheatsheet.php) online
that you may find useful.

## General Email Troubleshooting

First, you need to check that your MTA is delivering relevant
incoming emails to the `script/mailin` command.  There are various
ways of setting your MTA up to do this; we have documented
one way of doing it
[in Exim]({{ page.baseurl }}/docs/installing/email/#example-setup-on-exim4), including [a command you can use]({{ page.baseurl }}/docs/installing/email/#troubleshooting-exim) to check that the email
routing is set up correctly. We've also documented one way of setting up [Postfix]({{ page.baseurl }}/docs/installing/email/#example-setup-on-postfix), with a similar [debugging command]({{ page.baseurl }}/docs/installing/email/#troubleshooting-postfix).

Second, you need to test that the mailin script itself is working
correctly, by running it from the command line, First, find a
valid "To" address for a request in your system.  You can do this
through your site's admin interface, or from the command line,
like so:

    $ ./script/console
    Loading development environment (Rails 2.3.14)
    >> InfoRequest.find_by_url_title("why_do_you_have_such_a_fancy_dog").incoming_email
    => "request-101-50929748@localhost"

Now take the source of a valid email (there are some sample emails in
`spec/fixtures/files/`); edit the `To:` header to match this address;
and then pipe it through the mailin script.  A non-zero exit code
means there was a problem.  For example:

    $ cp spec/fixtures/files/incoming-request-plain.email /tmp/
    $ perl -pi -e 's/^To:.*/To: <request-101-50929748@localhost>/' /tmp/incoming-request-plain.email
    $ ./script/mailin < /tmp/incoming-request-plain.email
    $ echo $?
    75

The `mailin` script emails the details of any errors to
`CONTACT_EMAIL` (from your `general.yml` file). A common problem is
for the user that the MTA runs as not to have write access to
`files/raw_emails/`.

If everything seems fine locally, you should also check from another
computer connected to the Internet that the DNS for your chosen
domain indicates that your Alaveteli server is handling mail, and
that your server is receiving mail on port 25. The following
command is a query to ask which server is handling the mail for
the domain `example.com`, which receives the answer `mail.example.com`.

    $ host -t mx example.com
    example.com mail is handled by 5 mail.example.com.

This next command tries to connect to port 25, the standard SMTP
port, on `mail.example.com`, and is refused.

    $ telnet mail.example.com 25
    Trying 10.10.10.30...
    telnet: connect to address 10.10.10.30: Connection refused

The transcript below shows a successful connection where the server
accepts mail for delivery (the commands you would type are prefixed
by a `$`):

    $ telnet 10.10.10.30 25
    Trying 10.10.10.30...
    Connected to 10.10.10.30.
    Escape character is '^]'.
    220 mail.example.com ESMTP Exim 4.80 Tue, 12 Aug 2014 11:10:39 +0000
    $ HELO X
    250 mail.example.com Hello X [10.10.10.1]
    $ MAIL FROM: <test@local.domain>
    250 OK
    $ RCPT TO:<foi+request-1234@example.com>
    250 Accepted
    $ DATA
    354 Enter message, ending with "." on a line by itself
    $ Subject: Test
    $
    $ This is a test mail.
    $ .
    250 OK id=1XHA03-0001Vx-Qn
    QUIT


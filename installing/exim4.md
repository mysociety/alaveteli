---
layout: page
title: Installing MTA
---

# Installing the MTA

<p class="lead">
	Alaveteli sends and recieves email. You'll need to set up your Mail
	Transfer Agent (MTA) to handle this properly.
</p>

## Example setup on exim4

This page shows an example of how to set up your mail transfer agent (MTA).
These instructions are for **exim4** (running on Ubuntu) -- exim is one of the most
popular MTAs.

## Instructions

We suggest you add the following to your exim configuration.

In `/etc/exim4/conf.d/main/04_alaveteli_options`:

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
[`INCOMING_EMAIL_PREFIX`]({{ site.baseurl }}customising/config/#incoming_email_prefix)
in your config at `config/general.yml` to "foi+", create `config/aliases` with the following
content:

    ^foi\\+.*: |/path/to/alaveteli/software/script/mailin

You should also configure exim to discard any messages sent to the
[`BLACKHOLE_PREFIX`]({{ site.baseurl }}customising/config/#blackhole_prefix)
address, whose default value is
`do-not-reply-to-this-address`. For example, add the following to
`config/aliases`:

    # We use this for envelope from for some messages where we don't care about delivery
    do-not-reply-to-this-address:        :blackhole:

If you want to make use of the automatic bounce-message handling, then
set the 
[`TRACK_SENDER_EMAIL`]({{ site.baseurl }}customising/config/#track_sender_email)
address to be filtered through
`script/handle-mail-replies`. Messages that are not bounces or
out-of-office autoreplies will be forwarded to
[`FORWARD_NONBOUNCE_RESPONSES_TO`]({{ site.baseurl }}customising/config/#forward_nonbounce_responses_to).
For example, in WhatDoTheyKnow the
configuration looks like this:

    raw_team: [a list of people on the team]
    team:     |/path/to/alaveteli/software/script/handle-mail-replies

with `FORWARD_NONBOUNCE_RESPONSES_TO: 'raw_team@whatdotheyknow.com'`

Finally, make sure you have `dc_use_split_config='true'` in
`/etc/exim4/update-exim4.conf.conf`, and execute the command
`update-exim4.conf`.

Note that if the file `/etc/exim4/exim4.conf` exists then `update-exim4.conf`
will silently do nothing. Some distributions include this file. If
yours does, you will need to rename it before running `update-exim4.conf`.

(You may also want to set `dc_eximconfig_configtype='internet'`,
`dc_local_interfaces='0.0.0.0 ; ::1'`, and
`dc_other_hostnames='<your-host-name>'`)

## Troubleshooting

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

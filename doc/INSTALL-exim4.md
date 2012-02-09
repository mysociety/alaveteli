As an example of how to set up your MTA, in exim on Ubuntu, you might
add the following to its configuration.

In `/etc/exim4/conf.d/main/04_alaveteli_options`:

    ALAVETELI_HOME=/path/to/alaveteli/software
    ALAVETELI_USER=www-data
    log_file_path=/var/log/exim4/exim-%slog-%D
    MAIN_LOG_SELECTOR==+all -retry_defer 

(The user ALAVETELI_USER should have write permissions on ALAVETELI_HOME).

Note that the name and location of the log files created by Exim must match 
what the `load-exim-logs` script expects, hence the need for the extra
`log_file_path` setting. And the `check-recent-requests-sent` scripts expects
the logs to contain the `from=<...>` envelope information, so we make the 
logs more verbose with `log_selector`. 

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
    
And, assuming you set `OPTION_INCOMING_EMAIL_PREFIX` in your config at
`config/general` to "foi+", create `config/aliases` with the following
content:

    ^foi\\+.*: |/path/to/alaveteli/software/script/mailin

You should also configure exim to discard any messages sent to the `BLACKHOLE_PREFIX`
address, whose default value is 'do-not-reply-to-this-address'. For example, add the
following to config/aliases:

    # We use this for envelope from for some messages where we don't care about delivery
    do-not-reply-to-this-address:        :blackhole:

If you want to make use of the automatic bounce-message handling, then set the `TRACK_SENDER_EMAIL`
address to be filtered through `script/handle-mail-replies`. Messages that are not bounces or
out-of-office autoreplies will be forwarded to `FORWARD_NONBOUNCE_RESPONSES_TO`. For example,
in WhatDoTheyKnow the configuration looks like this:

    raw_team: [a list of people on the team]
    team:     |/path/to/alaveteli/software/script/handle-mail-replies

with `FORWARD_NONBOUNCE_RESPONSES_TO: 'raw_team@whatdotheyknow.com'`

Finally, make sure you have `dc_use_split_config='true'` in
`/etc/exim4/update-exim4.conf.conf`, and execute the command
`update-exim4.conf`

(You may also want to set `dc_eximconfig_configtype='internet'`,
`dc_local_interfaces='0.0.0.0 ; ::1'`, and
`dc_other_hostnames='<your-host-name>'`)

# Troubleshooting

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


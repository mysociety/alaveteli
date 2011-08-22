As an example of how to set up your MTA, in exim on Ubuntu, you might
add the following to its configuration.

In `/etc/exim4/conf.d/main/04_alaveteli_options`:

    ALAVETELI_HOME=/path/to/alaveteli/software
    ALAVETELI_USER=www-data

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

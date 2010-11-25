As an example of how to set up your MTA, in exim on Ubuntu, you might
add the following to its configuration.

In /etc/exim4/conf.d/main/04_wdtk_options:

  WDTK_HOME=/path/to/wdtk/software
  WDTK_USER=www-data

In /etc/exim4/conf.d/router/04_wdtk:

  wdtk_request:
     debug_print = "R: wdtk for $local_part@$domain"
     driver = redirect
     data = ${lookup{$local_part}wildlsearch{WDTK_HOME/config/aliases}}
     pipe_transport = wdtk_mailin_transport

In /etc/exim4/conf.d/transport/04_wdtk:

  wdtk_mailin_transport:
     driver = pipe
     command = $address_pipe ${lc:$local_part}
     current_directory = WDTK_HOME
     home_directory = WDTK_HOME
     user = WDTK_USER
     group = WDTK_USER
    
And, assuming you set OPTION_INCOMING_EMAIL_PREFIX to "foi+", this in
config/aliases:

  ^foi\+request-.*: |/path/to/wdtk/software/script/mailin

Finally, make sure you have `dc_use_split_config='true'` in
/etc/exim4/update-exim4.conf.conf, and execute the command
`update-exim4.conf`


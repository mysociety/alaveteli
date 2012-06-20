As an example of how to set up your MTA, in postfix on Ubuntu, you might
add the following to its configuration.

In /etc/postfix/master.cf:

  alaveteli unix  -	n	n	-	50	pipe
    flags=R user=ALAVETELI_USER argv=ALAVETELI_HOME/script/mailin

In /etc/postfix/main.cf

  virtual_alias_maps = regexp:/etc/postfix/regexp

For example

ALAVETELI_HOME=/path/to/alaveteli/software
ALAVETELI_USER=www-data

The user ALAVETELI_USER should have write permissions on ALAVETELI_HOME.

And, assuming you set `OPTION_INCOMING_EMAIL_PREFIX` in your config at
`config/general` to "foi+", create `/etc/postfix/regexp` with the following
content:

  /^foi.*/	alaveteli


You should also configure postfix to discard any messages sent to the `BLACKHOLE_PREFIX`
address, whose default value is 'do-not-reply-to-this-address'. For example, add the
following to /etc/aliases:

    # We use this for envelope from for some messages where we don't care about delivery
    do-not-reply-to-this-address:        :blackhole:

# Troubleshooting

To test mail delivery, run:
  
  $ /usr/sbin/sendmail -bv foi+requrest-1234@localhost

This tells you if sending the emails to 'foi\+.*localhost' is working. 

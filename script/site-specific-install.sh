#!/bin/sh

# Set IDEAL_VERSION to the commitish we want to check out; typically
# this is the version tag.  Since this may not exist before release,
# fall back to the master branch:
VERSIONS="origin/install-script 0.15 origin/master"

PARENT_SCRIPT_URL=https://github.com/mysociety/commonlib/blob/master/bin/install-site.sh

misuse() {
  echo The variable $1 was not defined, and it should be.
  echo This script should not be run directly - instead, please run:
  echo   $PARENT_SCRIPT_URL
  exit 1
}

# Strictly speaking we don't need to check all of these, but it might
# catch some errors made when changing install-site.sh

[ -z "$DIRECTORY" ] && misuse DIRECTORY
[ -z "$UNIX_USER" ] && misuse UNIX_USER
[ -z "$REPOSITORY" ] && misuse REPOSITORY
[ -z "$REPOSITORY_URL" ] && misuse REPOSITORY_URL
[ -z "$BRANCH" ] && misuse BRANCH
[ -z "$SITE" ] && misuse SITE
[ -z "$DEFAULT_SERVER" ] && misuse DEFAULT_SERVER
[ -z "$HOST" ] && misuse HOST
[ -z "$DISTRIBUTION" ] && misuse DISTRIBUTION
[ -z "$VERSIONS" ] && misuse VERSIONS
[ -z "$DEVELOPMENT_INSTALL" ] && misuse DEVELOPMENT_INSTALL
[ -z "$BIN_DIRECTORY" ] && misuse BIN_DIRECTORY

update_mysociety_apt_sources

if [ ! "$DEVELOPMENT_INSTALL" = true ]; then
    install_nginx
    add_website_to_nginx
    # Check out the first available requested version:
    su -l -c "cd '$REPOSITORY' && (for v in $VERSIONS; do git checkout $v && break; done)" \
        "$UNIX_USER"
fi

install_postfix

# Now there's quite a bit of Postfix configuration that we need to
# make sure is present:

ensure_line_present \
    "^ *alaveteli *unix *" \
    "alaveteli unix  -       n       n       -       50      pipe flags=R user=$UNIX_USER argv=$REPOSITORY/script/mailin" \
    /etc/postfix/master.cf 644

ensure_line_present \
    "^ *transport_maps *= *regexp:/etc/postfix/regexp" \
    "transport_maps = regexp:/etc/postfix/regexp" \
    /etc/postfix/main.cf 644

ensure_line_present \
    "^ *local_recipient_maps *=" \
    "local_recipient_maps = " \
    /etc/postfix/main.cf 644

ensure_line_present \
    "^ *mydestination *=" \
    "mydestination = $HOST, $(hostname --fqdn), localhost.localdomain, localhost" \
    /etc/postfix/main.cf 644

ensure_line_present \
    "^.*alaveteli" \
    "/^foi.*/	alaveteli" \
    /etc/postfix/regexp 644

ensure_line_present \
    "^do-not-reply" \
    "do-not-reply-to-this-address:        :blackhole:" \
    /etc/aliases 644

ensure_line_present \
    "^mail" \
    "mail.*                          -/var/log/mail/mail.log" \
    /etc/rsyslog.d/50-default.conf 644

if ! egrep '^ */var/log/mail/mail.log *{' /etc/logrotate.d/rsyslog
then
    cat >> /etc/logrotate.d/rsyslog <<EOF
/var/log/mail/mail.log {
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
fi

/etc/init.d/rsyslog restart

newaliases
postmap /etc/postfix/regexp
postfix reload

# (end of the Postfix configuration)

install_website_packages

# Make the PostgreSQL user a superuser to avoid the irritating error:
#   PG::Error: ERROR:  permission denied: "RI_ConstraintTrigger_16564" is a system trigger
# This is only needed for loading the sample data, so the superuser
# permissions are dropped below.
add_postgresql_user --superuser

export DEVELOPMENT_INSTALL
su -c "$BIN_DIRECTORY/install-as-user '$UNIX_USER' '$HOST' '$DIRECTORY'" "$UNIX_USER"

# Now that the install-as-user script has loaded the sample data, we
# no longer need the PostgreSQL user to be a superuser:
echo "ALTER USER \"$UNIX_USER\" WITH NOSUPERUSER;" | su -l -c 'psql' postgres

if [ ! "$DEVELOPMENT_INSTALL" = true ]; then
    install_sysvinit_script
fi

# Set up root's crontab:

cd "$REPOSITORY"

sed -r \
    -e "/foi-purge-varnish/d" \
    -e "s,^(MAILTO=).*,\1root@$HOST," \
    -e "s,\!\!\(\*= .user \*\)\!\!,$UNIX_USER,g" \
    -e "s,/data/vhost/\!\!\(\*= .vhost \*\)\!\!/\!\!\(\*= .vcspath \*\)\!\!,$REPOSITORY,g" \
    -e "s,/data/vhost/\!\!\(\*= .vhost \*\)\!\!,$DIRECTORY,g" \
    -e "s,run-with-lockfile,$REPOSITORY/commonlib/bin/run-with-lockfile.sh,g" \
    config/crontab-example > /etc/cron.d/alaveteli

sed -r \
    -e "s,\!\!\(\*= .user \*\)\!\!,$UNIX_USER,g" \
    -e "s,\!\!\(\*= .daemon_name \*\)\!\!,foi-alert-tracks,g" \
    -e "s,\!\!\(\*= .vhost_dir \*\)\!\!,$DIRECTORY,g" \
    config/alert-tracks-debian.ugly > /etc/init.d/foi-alert-tracks

chmod a+rx /etc/init.d/foi-alert-tracks

if [ $DEFAULT_SERVER = true ] && [ x != x$EC2_HOSTNAME ]
then
    # If we're setting up as the default on an EC2 instance, make sure
    # that the /etc/rc.local is set up to run the install script again
    # to update the hostname:
    overwrite_rc_local
fi

done_msg "Installation complete"; echo

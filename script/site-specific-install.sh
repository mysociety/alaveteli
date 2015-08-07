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

# Debian Squeeze Fixes
if [ x"$DISTRIBUTION" = x"debian" ] && [ x"$DISTVERSION" = x"squeeze" ]
then
  # Add wheezy repo to get bundler
  cat > /etc/apt/sources.list.d/debian-wheezy.list <<EOF
deb http://the.earth.li/debian/ wheezy main contrib non-free
EOF

  # Get bundler from wheezy repo and de-prioritise all other
  # wheezy packages
  cat >> /etc/apt/preferences <<EOF

Package: bundler
Pin: release n=wheezy
Pin-Priority: 990

Package: *
Pin: release n=wheezy
Pin-Priority: 50
EOF

apt-get -qq update
fi

# Ubuntu Precise Fixes
if [ x"$DISTRIBUTION" = x"ubuntu" ] && [ x"$DISTVERSION" = x"precise" ]
then
  cat > /etc/apt/sources.list.d/ubuntu-trusty.list <<EOF
deb http://archive.ubuntu.com/ubuntu/ trusty universe
deb-src http://archive.ubuntu.com/ubuntu/ trusty universe
EOF

  cat > /etc/apt/sources.list.d/mysociety-launchpad.list <<EOF
deb http://ppa.launchpad.net/mysociety/alaveteli/ubuntu precise main
deb-src http://ppa.launchpad.net/mysociety/alaveteli/ubuntu precise main
EOF

  # Get bundler from trusty and de-prioritise all other
  # trusty packages
  cat >> /etc/apt/preferences <<EOF

Package: ruby-bundler
Pin: release n=trusty
Pin-Priority: 990

Package: *
Pin: release n=trusty
Pin-Priority: 50
EOF

# Get the key for the mysociety ubuntu alaveteli repo
apt-get install -y python-software-properties
add-apt-repository -y ppa:mysociety/alaveteli

apt-get -qq update
fi

apt-get -y update

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
    "^ *transport_maps *=" \
    "transport_maps = regexp:/etc/postfix/transports" \
    /etc/postfix/main.cf 644

ensure_line_present \
    "^ *local_recipient_maps *=" \
    "local_recipient_maps = proxy:unix:passwd.byname regexp:/etc/postfix/recipients" \
    /etc/postfix/main.cf 644

ensure_line_present \
    "^ *mydestination *=" \
    "mydestination = $HOST, $(hostname --fqdn), localhost.localdomain, localhost" \
    /etc/postfix/main.cf 644

ensure_line_present \
    "^ *myhostname *=" \
    "myhostname = $(hostname --fqdn)" \
    /etc/postfix/main.cf 644

ensure_line_present \
    "^do-not-reply" \
    "do-not-reply-to-this-address:        :blackhole:" \
    /etc/aliases 644

ensure_line_present \
    "^mail" \
    "mail.*                          -/var/log/mail/mail.log" \
    /etc/rsyslog.d/50-default.conf 644

cat > /etc/postfix/transports <<EOF
/^foi.*/                alaveteli
EOF

cat > /etc/postfix/recipients <<EOF
/^foi.*/                this-is-ignored
/^postmaster@/          this-is-ignored
/^user-support@/        this-is-ignored
/^team@/                this-is-ignored
EOF

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
postmap /etc/postfix/transports
postmap /etc/postfix/recipients
postfix reload

# (end of the Postfix configuration)

install_website_packages

# Give the unix user membership of the adm group so that they can read the mail log files
usermod -a -G adm "$UNIX_USER"

# Make the PostgreSQL user a superuser to avoid the irritating error:
#   PG::Error: ERROR:  permission denied: "RI_ConstraintTrigger_16564" is a system trigger
# This is only needed for loading the sample data, so the superuser
# permissions are dropped below.
add_postgresql_user --superuser

# create the template_utf8 template we'll use for our databases
sudo -u postgres createdb -T template0 -E UTF-8 template_utf8
sudo -u postgres psql <<EOF
update pg_database set datistemplate=true, datallowconn=false where datname='template_utf8';
EOF

export DEVELOPMENT_INSTALL
su -l -c "$BIN_DIRECTORY/install-as-user '$UNIX_USER' '$HOST' '$DIRECTORY'" "$UNIX_USER"

# Now that the install-as-user script has loaded the sample data, we
# no longer need the PostgreSQL user to be a superuser:
echo "ALTER USER \"$UNIX_USER\" WITH NOSUPERUSER;" | su -l -c 'psql' postgres

# Set up root's crontab:

cd "$REPOSITORY"

echo -n "Creating /etc/cron.d/alaveteli... "
(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:convert_crontab DEPLOY_USER='$UNIX_USER' VHOST_DIR='$DIRECTORY' VCSPATH='$SITE' SITE='$SITE' CRONTAB=config/crontab-example" "$UNIX_USER") > /etc/cron.d/alaveteli
# There are some other parts to rewrite, so just do them with sed:
sed -r \
    -e "/$SITE-purge-varnish/d" \
    -e "s,^(MAILTO=).*,\1root@$HOST," \
    -i /etc/cron.d/alaveteli
echo $DONE_MSG

if [ ! "$DEVELOPMENT_INSTALL" = true ]; then
  echo -n "Creating /etc/init.d/$SITE... "
  (su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:convert_init_script DEPLOY_USER='$UNIX_USER' VHOST_DIR='$DIRECTORY' VCSPATH='$SITE' SITE='$SITE' SCRIPT_FILE=config/sysvinit-thin.example" "$UNIX_USER") > /etc/init.d/"$SITE"
  chgrp "$UNIX_USER" /etc/init.d/"$SITE"
  chmod 754 /etc/init.d/"$SITE"
  echo $DONE_MSG
fi

echo -n "Creating /etc/init.d/$SITE-alert-tracks... "
(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:convert_init_script DEPLOY_USER='$UNIX_USER' VHOST_DIR='$DIRECTORY' SCRIPT_FILE=config/alert-tracks-debian.example" "$UNIX_USER") > /etc/init.d/"$SITE-alert-tracks"
chgrp "$UNIX_USER" /etc/init.d/"$SITE-alert-tracks"
chmod 754 /etc/init.d/"$SITE-alert-tracks"
echo $DONE_MSG

if [ $DEFAULT_SERVER = true ] && [ x != x$EC2_HOSTNAME ]
then
    # If we're setting up as the default on an EC2 instance, make sure
    # that the /etc/rc.local is set up to run the install script again
    # to update the hostname:
    overwrite_rc_local
fi

done_msg "Installation complete"; echo

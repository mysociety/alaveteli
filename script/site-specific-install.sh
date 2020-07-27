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

install_dovecot() {
  echo -n "Installing dovecot... "
  apt-get install -qq -y dovecot-pop3d >/dev/null
  echo $DONE_MSG
}

install_mailutils() {
  echo -n "Installing mailutils... "
  apt-get install -qq -y mailutils >/dev/null
  echo $DONE_MSG
}

clear_daemon() {
  echo -n "Removing /etc/init.d/$SITE-$1... "
  rm -f "/etc/init.d/$SITE-$1"
  echo $DONE_MSG
}

install_daemon() {
  echo -n "Creating /etc/init.d/$SITE-$1... "
  (su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:convert_init_script DEPLOY_USER='$UNIX_USER' VHOST_DIR='$DIRECTORY' RUBY_VERSION='$RUBY_VERSION' SCRIPT_FILE=config/$1-debian.example" "$UNIX_USER") > /etc/init.d/"$SITE-$1"
  chgrp "$UNIX_USER" /etc/init.d/"$SITE-$1"
  chmod 754 /etc/init.d/"$SITE-$1"

  if which systemctl > /dev/null
  then
    systemctl enable "$SITE-$1"
  fi

  echo $DONE_MSG
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

# Ubuntu Bionic Fixes
if [ x"$DISTRIBUTION" = x"ubuntu" ] && [ x"$DISTVERSION" = x"bionic" ]
then
  # Remove old cosmic repo that's no longer available
  rm --force /etc/apt/sources.list.d/ubuntu-cosmic.list

  # Add focal repo to get pdftk-java
  cat > /etc/apt/sources.list.d/ubuntu-focal.list <<EOF
deb http://archive.ubuntu.com/ubuntu/ focal universe
deb-src http://archive.ubuntu.com/ubuntu/ focal universe
EOF

  # De-prioritise all packages from focal. We only add the repo to install
  # pdftk-java, as pdftk is not available in bionic.
  cat > /etc/apt/preferences.d/ubuntu-focal.pref <<EOF
Package: *
Pin: release n=focal
Pin-Priority: 50
EOF

  apt-get -qq update
fi

apt-get -y update

echo 'Setting hostname...'
hostnamectl set-hostname $HOST

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
/^foi\+.*@$HOST$/                alaveteli
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

# use ruby 2.3.3, 2.1.5 if it's already the default
# (i.e. 'stretch', 'jessie')
if ruby --version | grep -q 'ruby 2.3.3' > /dev/null
then
  echo 'using ruby 2.3.3'
  RUBY_VERSION='2.3.3'
elif ruby --version | grep -q 'ruby 2.1.5' > /dev/null
then
  echo 'using ruby 2.1.5'
  RUBY_VERSION='2.1.5'
elif ruby --version | grep -q 'ruby 1.9.3' > /dev/null
then
  # Set ruby version to 2.1.x
  update-alternatives --set ruby /usr/bin/ruby2.1
  update-alternatives --set gem /usr/bin/gem2.1
  echo 'using ruby 2.1.5'
  RUBY_VERSION='2.1.5'
fi

# Give the unix user membership of the adm group so that they can read the mail log files
usermod -a -G adm "$UNIX_USER"

# Make the PostgreSQL user a superuser to avoid the irritating error:
#   PG::Error: ERROR:  permission denied: "RI_ConstraintTrigger_16564" is a system trigger
# This is only needed for loading the sample data, so the superuser
# permissions are dropped below.
add_postgresql_user --superuser

# create the template_utf8 template we'll use for our databases
echo -n "Checking for postgres template_utf8 database... "
if ! sudo -u postgres psql --list | grep template_utf8 > /dev/null; then
  sudo -u postgres createdb -T template0 -E UTF-8 template_utf8
  echo -n "Created."
fi

sudo -u postgres psql -q <<EOF
update pg_database set datistemplate=true, datallowconn=false where datname='template_utf8';
EOF

echo $DONE_MSG

export DEVELOPMENT_INSTALL
su -l -c "$BIN_DIRECTORY/install-as-user '$UNIX_USER' '$HOST' '$DIRECTORY' '$RUBY_VERSION'" "$UNIX_USER"

# Now that the install-as-user script has loaded the sample data, we
# no longer need the PostgreSQL user to be a superuser:
echo "ALTER USER \"$UNIX_USER\" WITH NOSUPERUSER;" | su -l -c 'psql' postgres


RETRIEVER_METHOD=$(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:get_config_value KEY=PRODUCTION_MAILER_RETRIEVER_METHOD" "$UNIX_USER")
if [ x"$RETRIEVER_METHOD" = x"pop" ] && [ "$DEVELOPMENT_INSTALL" = true ]; then

  # Install dovecot
  install_dovecot

  # Install mailutils
  install_mailutils

  ensure_line_present \
      "^\#* *listen" \
      "listen = *, ::" \
      /etc/dovecot/dovecot.conf 644


  ensure_line_present \
      "^\#* *log_path" \
      "log_path = /var/log/dovecot.log" \
      /etc/dovecot/dovecot.conf 644

  # Add a user to handle incoming mail
  if id "alaveteli-incoming" 2> /dev/null > /dev/null
    then
        echo "Incoming mail user already exists"
    else
        adduser --quiet --disabled-password --gecos "An incoming mail user for the site $SITE" "alaveteli-incoming"
        usermod --groups mail --password `openssl passwd -1 alaveteli-incoming` alaveteli-incoming
  fi
 elif [ x"$RETRIEVER_METHOD" = x"pop" ]; then

  echo "Warning: No POP server has been setup, please install your own securely"
  echo "or use a remote one."

fi

# Set up root's crontab:

cd "$REPOSITORY"


if [ "$DEVELOPMENT_INSTALL" = true ]; then
  # Not in the Gemfile due to conflicts
  # See: https://github.com/sj26/mailcatcher/blob/3079a00/README.md#bundler
  gem install mailcatcher
fi


echo -n "Creating /etc/cron.d/alaveteli... "
(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:convert_crontab DEPLOY_USER='$UNIX_USER' VHOST_DIR='$DIRECTORY' VCSPATH='$SITE' SITE='$SITE' RUBY_VERSION='$RUBY_VERSION' CRONTAB=config/crontab-example" "$UNIX_USER") > /etc/cron.d/alaveteli
# There are some other parts to rewrite, so just do them with sed:
sed -r \
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

# Clear existing daemons
all_daemons=$(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:all_daemons" "$UNIX_USER")
echo "Clearing any existing daemons"
for daemon in $all_daemons
do
  clear_daemon $daemon
done

# Install required daemons
active_daemons=$(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:active_daemons" "$UNIX_USER")
echo "Creating daemons for active daemons"
for daemon in $active_daemons
do
  install_daemon $daemon
done

if which systemctl > /dev/null
then
  systemctl daemon-reload
fi

if [ $DEFAULT_SERVER = true ] && [ x != x$EC2_HOSTNAME ]
then
    # If we're setting up as the default on an EC2 instance, make sure
    # that the /etc/rc.local is set up to run the install script again
    # to update the hostname:
    overwrite_rc_local
fi

done_msg "Installation complete"; echo

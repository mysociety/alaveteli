#!/bin/sh

# Set IDEAL_VERSION to the committish we want to check out; typically
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
  path=$1
  if [ $path = "/etc/init.d" ]; then name="$SITE-$2"; fi
  if [ $path = "/etc/systemd/system" ]; then name="$SITE.$2"; fi

  echo -n "Removing $path/$name... "
  rm -f "$path/$name"
  echo $DONE_MSG
}

install_daemon() {
  path=$1
  if [ $path = "/etc/init.d" ]; then name="$SITE-$2"; fi
  if [ $path = "/etc/systemd/system" ]; then name="$SITE.$2"; fi

  echo -n "Creating $path/$name... "
  (su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:convert_daemon DEPLOY_USER='$UNIX_USER' VHOST_DIR='$DIRECTORY' VCSPATH='$SITE' SITE='$SITE' RUBY_VERSION='$RUBY_VERSION' USE_RBENV=$USE_RBENV RAILS_ENV='$RAILS_ENV' RAILS_ENV_DEFINED='$RAILS_ENV_DEFINED' DAEMON=$2" "$UNIX_USER") > $path/$name
  chgrp "$UNIX_USER" $path/$name
  chmod 754 $path/$name

  if which systemctl > /dev/null
  then
    systemctl enable "$name"
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
[ -z "$VERSIONS" ] && misuse VERSIONS
[ -z "$DEVELOPMENT_INSTALL" ] && misuse DEVELOPMENT_INSTALL
[ -z "$BIN_DIRECTORY" ] && misuse BIN_DIRECTORY

update_mysociety_apt_sources

apt-get -y update

install_website_packages

if [ -f $REPOSITORY/config/general.yml ]; then
    STAGING_SITE=$(su -l -c "cd '$REPOSITORY' && RBENV_VERSION='system' bin/config STAGING_SITE" "$UNIX_USER")
    if ([ "$STAGING_SITE" = "0" ] && [ "$DEVELOPMENT_INSTALL" = "true" ]) ||
      ([ "$STAGING_SITE" = "1" ] && [ "$DEVELOPMENT_INSTALL" != "true" ]); then
        cat <<-END

    *****************************************************************
    ERROR: Configuration mismatch

    In config/general.yml you have STAGING_SITE set to $STAGING_SITE but you're
    running the install script with DEVELOPMENT_INSTALL set to $DEVELOPMENT_INSTALL

    Please either update config/general.yml or change the flags used
    when invoking the install script
    *****************************************************************

END

        exit 1
    fi
fi

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

if ! egrep '^ */var/log/mail/mail.log *{' /etc/logrotate.d/rsyslog > /dev/null
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

if which systemctl > /dev/null && systemctl is-active --quiet rsyslog
then
  systemctl restart rsyslog.service
elif [ -f /etc/init.d/rsyslog ]
then
  /etc/init.d/rsyslog restart
fi

newaliases
postmap /etc/postfix/transports
postmap /etc/postfix/recipients
postfix reload

# (end of the Postfix configuration)

# Ensure we have required Ruby version from the current distribution package, if
# not then install using rbenv
if [ -f $REPOSITORY/.ruby-version ]; then
  required_ruby="$(cat $REPOSITORY/.ruby-version)"
else
  required_ruby="$(cat $REPOSITORY/.ruby-version.example)"
fi
current_ruby="$(ruby --version | awk 'match($0, /[0-9\.]+/) {print substr($0,RSTART,RLENGTH)}')"
if [ "$(printf '%s\n' "$required_ruby" "$current_ruby" | sort -V | head -n1)" = "$required_ruby" ]; then
  echo "Current Ruby (${current_ruby}) is greater than or equal to required version (${required_ruby})"
  RUBY_VERSION=$current_ruby
  USE_RBENV=false
else
  echo "Current Ruby (${current_ruby}) is less than required version (${required_ruby})"
  echo "Installing packages required for ruby-build..."
  xargs -a "$REPOSITORY/config/packages.ruby-build" apt-get -qq -y install >/dev/null
  RUBY_VERSION=$required_ruby
  USE_RBENV=true
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
su -l -c "$BIN_DIRECTORY/install-as-user '$UNIX_USER' '$HOST' '$DIRECTORY' '$RUBY_VERSION' '$USE_RBENV' '$DEVELOPMENT_INSTALL'" "$UNIX_USER"

# Now that the install-as-user script has loaded the sample data, we
# no longer need the PostgreSQL user to be a superuser:
echo "ALTER USER \"$UNIX_USER\" WITH NOSUPERUSER;" | su -l -c 'psql' postgres


RETRIEVER_METHOD=$(su -l -c "cd '$REPOSITORY' && bin/config PRODUCTION_MAILER_RETRIEVER_METHOD" "$UNIX_USER")
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

cd "$REPOSITORY"

if [ -f config/rails_env.rb ]; then
  RAILS_ENV_DEFINED=$(ruby -r ./config/rails_env.rb -e "puts ENV.keys.include?('RAILS_ENV')")
else
  RAILS_ENV_DEFINED=false
fi

if [ "$DEVELOPMENT_INSTALL" = true ]; then
  RAILS_ENV=development
else
  RAILS_ENV=production
fi

if [ "$DEVELOPMENT_INSTALL" = true ]; then
  # Not in the Gemfile due to conflicts
  # See: https://github.com/sj26/mailcatcher/blob/3079a00/README.md#bundler
  gem install mailcatcher --no-document
fi

# Set up root's crontab:
echo -n "Creating /etc/cron.d/alaveteli... "
(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:convert_crontab DEPLOY_USER='$UNIX_USER' VHOST_DIR='$DIRECTORY' VCSPATH='$SITE' SITE='$SITE' RUBY_VERSION='$RUBY_VERSION' USE_RBENV=$USE_RBENV RAILS_ENV='$RAILS_ENV' CRONTAB=config/crontab-example" "$UNIX_USER") > /etc/cron.d/alaveteli
# There are some other parts to rewrite, so just do them with sed:
sed -r \
    -e "s,^(MAILTO=).*,\1root@$HOST," \
    -i /etc/cron.d/alaveteli
echo $DONE_MSG

# Set up root's crontab:
echo -n "Creating /etc/logrotate.d/alaveteli... "
(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:convert VHOST_DIR='$DIRECTORY' VCSPATH='$SITE' FILE=config/logrotate-example" "$UNIX_USER") > /etc/logrotate.d/alaveteli
echo $DONE_MSG

# Clear existing legacy daemons if present
if [ -f /etc/init.d/$SITE ]
then
  echo "Clearing any legacy daemons"
  echo -n "Removing /etc/init.d/$SITE... "
  rm -f "/etc/init.d/$SITE"
  echo $DONE_MSG
fi

for path in "/etc/init.d" "/etc/systemd/system"; do
  # Clear existing daemons
  all_daemons=$(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:all_daemons PATH='$path' SITE='$SITE'" "$UNIX_USER")
  echo "Clearing any existing $path daemons"
  for daemon in $all_daemons
  do
    clear_daemon $path $daemon
  done

  # Install required daemons
  active_daemons=$(su -l -c "cd '$REPOSITORY' && bundle exec rake config_files:active_daemons PATH='$path'" "$UNIX_USER")
  echo "Creating daemons for active $path daemons"
  for daemon in $active_daemons
  do
    install_daemon $path $daemon
  done
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

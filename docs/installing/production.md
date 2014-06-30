---
layout: page
title: Production installation
---

`sudo` is not installed on Debian by default. Make sure your system is up-to-date and install it.

    # run as root!
    # Update sources and current packages
    apt-get update -y
    apt-get upgrade -y

    # Install useful tools
    apt-get install -y sudo vim git-core

    # Configure locales
    # Log out of teh SSH session and log back in to use the SSH session locale
    dpkg-reconfigure locales

    # Create a user to run the app
    # adduser --quiet --disabled-password --no-create-home --gecos "Alaveteli" alaveteli
    adduser --quiet --disabled-password --gecos "Alaveteli" alaveteli

    # Create the target directory and clone alaveteli
    mkdir /opt/alaveteli
    chown alaveteli:alaveteli /opt/alaveteli
    sudo -u alaveteli git clone --recursive --branch master \
      https://github.com/mysociety/alaveteli.git /opt/alaveteli

    # Add Debian Backports repository
    cat > /etc/apt/sources.list.d/debian-backports.list <<EOF
    deb http://backports.debian.org/debian-backports squeeze-backports main contrib non-free
    EOF

    # Add mySociety repository
    cat > /etc/apt/sources.list.d/mysociety-debian.list <<EOF
    deb http://debian.mysociety.org squeeze main
    EOF

    wget -O - https://debian.mysociety.org/debian.mysociety.org.gpg.key | apt-key add -

    # Reduce the priority of the mySociety repository
    # cat > /etc/apt/preferences <<EOF
    # Package: *
    # Pin: origin debian.mysociety.org
    # Pin-Priority: 500
    # EOF

    # Update the sources
    apt-get update -y

    # Install required packages
    apt-get install -y $(cat /opt/alaveteli/config/packages.debian-squeeze)

    # Install bundler
    gem install bundler --no-rdoc --no-ri

    # Create the database user and databases
    # Enter password for database user
    sudo -u postgres createuser -s -P foi
    sudo -u postgres createdb -T template0 -E UTF-8 -O foi alaveteli_production
    sudo -u postgres createdb -T template0 -E UTF-8 -O foi alaveteli_test
    sudo -u postgres createdb -T template0 -E UTF-8 -O foi alaveteli_development

    # Copy the config files
    # Edit for your install
    cp /opt/alaveteli/config/database.yml-example /opt/alaveteli/config/database.yml
    cp /opt/alaveteli/config/general.yml-example /opt/alaveteli/config/general.yml
    cp /opt/alaveteli/config/newrelic.yml-example /opt/alaveteli/config/newrelic.yml
    chown alaveteli:alaveteli /opt/alaveteli/config/{database,general,newrelic}.yml
    chmod 640 /opt/alaveteli/config/{database,general,newrelic}.yml

    # Run the post-deployment tasks
    sudo -u alaveteli /opt/alaveteli/script/rails-post-deploy
    
    # needs a RAILS_ENV
    # Breaks with RAILS_ENV=production
    # Works with RAILS_ENV=development
    sudo -u alaveteli RAILS_ENV=production /opt/alaveteli/script/rebuild-xapian-index

    # Generate crontab and init scripts

    cd /opt/alaveteli

    bundle exec rake config_files:convert_crontab \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/opt \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      MAILTO=example@example.org \
      CRONTAB=/opt/alaveteli/config/crontab-example > /etc/cron.d/alaveteli

    # TODO: Requires origin/alert-tracks-generator
    # TODO: Document that you need to name the output file correctly
    bundle exec rake config_files:convert_init_script \
      DEPLOY_USER=alaveteli \
      VHOST_DIR=/opt \
      VCSPATH=alaveteli \
      SITE=alaveteli \
      SCRIPT_FILE=/opt/alaveteli/config/alert-tracks-debian.ugly > /etc/init.d/{SITE}-alert-tracks

    chown root:alaveteli /etc/cron.d/alaveteli
    chmod 754 /etc/cron.d/alaveteli

    chown root:alaveteli /etc/init.d/{SITE}-alert-tracks
    chmod 754 /etc/init.d/{SITE}-alert-tracks

    # NOTE: You may need to replace `alaveteli` with the name you gave the
    # daemon with the SITE variable when running
    # rake config_files:convert_init_script
    service alaveteli-alert-tracks start

    # TODO: Test mail config:

    apt-get install -y exim4

    cat > /etc/exim4/conf.d/main/04_alaveteli_options <<EOF
    ALAVETELI_HOME=/opt/alaveteli
    ALAVETELI_USER=alaveteli
    log_file_path=/var/log/exim4/exim-%slog-%D
    MAIN_LOG_SELECTOR==+all -retry_defer
    extract_addresses_remove_arguments=false
    EOF

    # TODO: Configure Web server:

    # Add passenger/nginx
    apt-get install apt-transport-https ca-certificates
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7

    cat > /etc/apt/sources.list.d/passenger.list <<EOF
    deb https://oss-binaries.phusionpassenger.com/apt/passenger squeeze main
    EOF

    chown root: /etc/apt/sources.list.d/passenger.list
    chmod 600 /etc/apt/sources.list.d/passenger.list
    apt-get update -y

    apt-get install -y nginx-extras passenger



















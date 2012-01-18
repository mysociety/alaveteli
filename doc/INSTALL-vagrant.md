WIP: These are a work in progress - there's still plenty to be done and we also
need to get the manual commands run below into the Chef config.

These instructions will get you up and running using Alaveteli with
[Vagrant](http://vagrantup.com) to create a development virtual machine.

First of all install dependencies like VirtualBox and then install Vagrant
`gem install vagrant`.

Clone the Alaveteli repo then run these commands from the repo directory:

    # Download, install and run VM
    vagrant up
    # SSH to the new box
    vagrant ssh

    # Create the databases
    sudo su - postgres
    echo "CREATE DATABASE foi_development encoding = 'UTF8';
    CREATE DATABASE foi_test encoding = 'UTF8';
    CREATE USER foi WITH CREATEUSER;
    ALTER USER foi WITH PASSWORD 'foi';
    ALTER USER foi WITH CREATEDB;
    GRANT ALL PRIVILEGES ON DATABASE foi_development TO foi;
    GRANT ALL PRIVILEGES ON DATABASE foi_test TO foi;
    ALTER DATABASE foi_development OWNER TO foi;
    ALTER DATABASE foi_test OWNER TO foi;" | psql

    # Create DB config file
    cp /vagrant/config/database.yml-example /vagrant/config/database.yml
    sed -i -e 's/<username>/foi/g' /vagrant/config/database.yml-example
    sed -i -e 's/<password>/foi/g' /vagrant/config/database.yml-example

    # Start the development server
    /vagrant/script/server

Now visit `localhost:3000`.

These instructions will get you up and running using Alaveteli with
[Vagrant](http://vagrantup.com) to create a development virtual machine.

First of all install dependencies like VirtualBox and then install Vagrant
`gem install vagrant`.

Clone the Alaveteli repo, clone the submodules `git submodule update --init`,
then run these commands from the repo directory:

    # Download, install and run VM (NOTE: will download at least 500MB)
    vagrant up

    # SSH to the new box and switch to the Alaveteli directory
    vagrant ssh
    cd /vagrant

    # Accept the RVM warning

    # Setup the database
    rake db:create && rake db:migrate

    # Load sample data and index it
    ./script/load-sample-data
    ./script/rebuild-xapian-index

    # Start the development server
    ./script/server

Now visit `http://localhost:3000`.

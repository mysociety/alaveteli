WIP: These are a work in progress - there's still plenty to be done and we also
need to get the manual commands run below into the Chef config.

These instructions will get you up and running using Alaveteli with
[Vagrant](http://vagrantup.com) to create a development virtual machine.

First of all install dependencies like VirtualBox and then install Vagrant
`gem install vagrant`.

Clone the Alaveteli repo then run these commands from the repo directory:

    # Download, install and run VM
    vagrant up

    # SSH to the new box and switch to the Alaveteli directory
    vagrant ssh
    cd vagrant

    # Migrate the database
    rake db:migrate

    # Start the development server
    ./script/server

Now visit `localhost:3000`.

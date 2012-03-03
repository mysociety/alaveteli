Using Vagrant for development
=============================

These instructions will get you up and running using Alaveteli with
[Vagrant](http://vagrantup.com) to create a development virtual machine.

Setup
-----

First of all install dependencies like VirtualBox and then install Vagrant:
`gem install vagrant`.

You'll also need `nfsd` installed on your machine for NFS shared folders. This
is required for performance reasons. On Ubuntu install the `nfs-server`
package.

Usage
-----

### Clone the Alaveteli repo

    git clone https://github.com/sebbacon/alaveteli.git
    cd alaveteli

### Clone the submodules

    git submodule update --init

### Download, install and run VM

NOTE: This will download at least 400MB and take some time (30 minutes with a
broadband internet connection). This time and downloading is only required the
first time you run this command.

You'll be asked for your password to sudo - this is required to create NFS
shared folders.

    vagrant up

### SSH to the new box and switch to the Alaveteli directory

    vagrant ssh
    cd /vagrant

### Setup the database

    rake db:create && rake db:migrate

### Load sample data and index it

    ./script/load-sample-data && ./script/rebuild-xapian-index

### Run the tests

    rake

### Start the development server

    ./script/server

### And you're golden

Now visit `http://localhost:3000` on your local machine to see your hard work.
Edit files on your local machine and see the changes reflected when you refresh
your browser. To run tests, SSH to the Vagrant machine with `vagrant ssh`.

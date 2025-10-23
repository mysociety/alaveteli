# Nix based development environment for alaveteli

Use `nix` to get a working dev environment for alaveteli with:

- a postgres database
- a redis cache server
- a local mailserver (mailpit) which shows emails in a webpage

To start:

- install nix:
  - https://nix.dev/install-nix
  - or https://lix.systems/install if you like pink and icecream :)

- make sure you have enough free space on your disk (10+GB) as nix will download everything that is needed to run
  alaveteli (even if you "already have it")
- run `nix develop --no-pure-eval` in this folder.
- go grab a cup of coffee or something :D
  After a few moments, you should see your prompt change with a clear message that you are in the dev env.
- run `devenv up` to start the services you need, and alaveteli itself. Keep that running while you're developing
- open a second term, and run `nix develop --no-pure-eval` again if you need a term in the dev env for various commands,
  like `rails c` and so on...
- you can edit your code as usual (no need to mount docker volumes and so on) and commit as you normally would

## Why nix?

`nix` is a package manager that is designed to avoid conflicts with whatever you have on your computer. It is made to do
deployments properly, so that the "it works on my machine" finally disappears from our vocabulary.
It does a lot of this by putting everything it needs (programs, libraries, config files...) under `/nix/store/` which it
manages by itself (do not go and mess with the contents of that folder! let `nix` take care of it).

When using it for development environments, it puts everything you need in there (ruby, postgresql, gems, etc...) so that
these don't conflict with whatever is already on your machine. And conversely, the alaveteli devenv won't mess up other
projects you have setup on your machine.

## Why bundix?

`bundix` is a wrapper around ruby's `bundle` which makes the process of using/install gems a bit more reproducible. It
essentially adds a hash for each gem to a `gemset.nix` file, which ensures you are downloading the expected file. There
is also caching that comes for free from nix, which helps speed up installation of the required gems.
These steps mean that there is no more imperative action (bundle install) required after the env or deployment has been
computed, so it's one less point of failure at start time.

## How the nix setup is organized for Alaveteli

`Alaveteli` (or rails?) expects a variety of files under `Rails.root`. With `nix`, these end up under a read-only
`/nix/store/<somehash>/` folder, where they cannot be modified at runtime.

In production, the "live" files (such as the xapian index, raw files...) are therefore moved out of the rails code tree, to `/var/lib/alaveteli`, and the alaveteli code base is patched where needed to go look for these files in the right place.

During development, files remain under `Rails.root` as you are used to:

- if you work on the alaveteli code base, just work in this folder.
- if you are modifying a theme for a specific site, clone your theme repo in the same parent folder as this one (so that you
  have `./yourtheme` and `./alaveteli` under the same folder), activate the devenv in this folder (see above) and then
  modify your code

## Running tests

This `nix` setup does not try to replicate the alaveteli test suite written in ruby. Instead it focuses on making sure
that the deployment is functional. Things like checking the email server is working, that rails can talk to it, that
some key routes do function, etc...

`nix` tests work by building a VM image which contains the whole deployments, running it and running a few checks
against it.

These can be run interactively:

```bash
# requires lix built from main (as of sept 1, 2025) to have self.submodules support
# once 2.94 is released, it should be ok to revert to stable
# build_tests:
nix -L build  --no-pure-eval --extra-experimental-features flake-self-attrs .#serverTests.driverInteractive
# run_tests (results is created by the command above)
./result/bin/nixos-test-driver --interactive

# To build lix from its master branch before 2.94 is released:
# 	sudo -i -H --preserve-env=SSH_AUTH_SOCK nix --experimental-features 'nix-command flakes' profile install --profile /nix/var/nix/profiles/default git+https://git.lix.systems/lix-project/lix --priority 3
```

Alternatively, the tests can be run non-interactively, for instance in CI:

```bash
nix -L build  --no-pure-eval --extra-experimental-features flake-self-attrs .#serverTests
```

# Nix based development environment for alaveteli

Use `nix` to get a working dev environment for alaveteli with:

- a postgres database
- a redis cache server
- a local mailserver (mailpit) which shows emails in a webpage

To start:

- install nix
- make sure you have enough free space on your disk (10+GB)
- run `nix develop --no-pure-eval` in this folder.
- go grab a cup of coffee or something :D
  After a few moments, you should see your prompt changing to say "devenv-shell-env". Now you have access to all the tools
  you need
- run `devenv up` to start the services you need, and alaveteli itself. Keep that running while you're developing
- open a second term, and run `nix develop --no-pure-eval` again if you need a term in the dev env for various commands,
  like `rails c` and so on...
- you can edit your code as usual (no need to mount docker volumes and so on) and commit as you normally would

## Why nix?

`nix` is a package manager that is designed to avoid conflicts with whatever you have on your computer. It is made to do
deployments properly, so that the "it works on my machine" finally disappears from our vocabulary.
It does a lot of this by putting everything it needs (programs, libraries, config files...) under `/nix/store/` which it
manages by itself (do not go and mess with the contents of that folder! let `nix` take care of it).

When using it for development environments, it put everything you need in there (ruby, postgresql, gems, etc...) so that
these don't conflict with whatever is already on your machine. And conversely, the alaveteli devenv won't mess up other
projects you have setup on your machine.

## Why bundix?

`bundix` is a wrapper around ruby's `bundle` which makes the process of using/install gems a bit more reproducible. It
essentially adds a hash for each gem to a `gemset.nix` file, which ensures you are downloading the expected file. There
is also caching that comes for free from nix, which helps speed up installation of the required gems.
These steps mean that there is no more imperative action (bundle install) required after the env or deployment has been
computed, so it's one less point of failure at start time.

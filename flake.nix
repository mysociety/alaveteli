{
  description = "Ruby environment for Alaveteli development using devenv.sh";
  # to start the shell:
  # nix develop --no-pure-eval (to setup the dev shell)
  # devenv up (to start pg, redis... services)
  # bundle exec rails db:migrate
  # bundle exec rails db:seed
  # bundle exec rails s

  # QUESTIONS
  # - where to run migrations?
  # - how to best build dev env conf files for rails (which have
  #   hardcoded paths in ./config/*?

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    nixpkgs-21_11.url = "github:nixos/nixpkgs/nixos-21.11";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs = { nixpkgs.follows = "nixpkgs"; };
  };

  nixConfig = {
    extra-trusted-public-keys =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, nixpkgs-21_11, devenv, systems, ... }@inputs:
    let forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
        devenv-test = self.devShells.${system}.default.config.test;
      });

      devShells = forEachSystem (system:
        let
          dbUser = "postgres";
          dbHost = "localhost";
          dbPort = 54321;
          pkgs = nixpkgs.legacyPackages.${system};
          toYAML = nixpkgs.lib.generators.toYAML { };
          rails_db_conf_file = pkgs.writeText "database.yml" (toYAML {
            # this config must be overridden in the theme
            development = {
              adapter = "postgresql";
              template = "template_utf8";
              host = dbHost;
              port = dbPort;
              database = "alaveteli_development";
              username = dbUser;
              password = "changeme";
            };
          });
          # alaveteli_config = nixpkgs.writeText
        in {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;

            modules = [{
              # https://devenv.sh/reference/options/
              packages = with pkgs; [
                libpqxx
                # node
                nodePackages.yarn
                libsass
                catdoc
                elinks
                file # libmagic
                ghostscript
                gnuplot
                icu
                imagemagick
                krb5
                postgresql_13
                libzip
                pdftk
                poppler
                poppler_utils
                tnef
                unrtf
                xapian
                wv
                # For gem: Nokogiri
                libiconv
                libxml2
                libxslt
                transifex-cli
                zlib
                # For gem: psych
                libyaml
              ];

              enterShell = ''
                # FIXME: where should we run `git submodule update`?
                # TODO: move init scripts to a custom command to speed up shell start?
                # why does it install in the current source tree? can it all be moved in the nix store?
                bundle
                cp config/storage.yml-example config/storage.yml
                cp config/general.yml-example config/general.yml
                rm -f config/database.yml
                ln -s "${rails_db_conf_file}" config/database.yml
                echo "Alaveteli core dev env ready"
                echo "The services you need are all running (postgres, redis...)"
                echo "useful commands:"
                echo "rails c (no path, just this!)"
                echo "rails dev (same here)"
              '';

              # this is required by the pg gem on linux
              env = {
                LD_LIBRARY_PATH =
                  nixpkgs.lib.makeLibraryPath [ pkgs.krb5 pkgs.openldap ];
              };

              # FIXME: change db port to avoid conflict with pre-existing postgres instance
              services.postgres = {
                enable = true;
                package = pkgs.postgresql_13;
                initialDatabases = [
                  {
                    name = "alaveteli_test";
                    user = dbUser;
                  }
                  {
                    name = "alaveteli_development";
                    user = dbUser;
                  }
                  {
                    name = "alaveteli_production";
                    user = dbUser;
                  }
                ];
                initialScript =
                  "CREATE ROLE postgres SUPERUSER; ALTER ROLE postgres WITH LOGIN;";
                listen_addresses = dbHost;
                port = dbPort;
                extensions = extensions: [ ];
              };
              services.mailpit = { enable = true; };
              services.redis = { enable = true; };
              languages.ruby = {
                enable = true;
                version = "3.4";
                bundler.enable = true;
              };
            }];
          };
        });
    };
}

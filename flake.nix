{
  description = "Ruby environment for Alaveteli development using devenv.sh";
  # to start the shell:
  # nix develop --no-pure-eval (to setup the dev shell)
  # devenv up (to start pg, redis... services)
  # you're ready to code!

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
          railsPort = "3030"; # to avoid conflict with commonly used 3000
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
          # ideally, this would load general.yml-example and override its contents
          # with whatever is passed below
          alaveteli_config_general = pkgs.writeText "general.yml" (toYAML {
            OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS = "publicbody@localhost";
          });
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
                figlet # for the text banner in the dev shell
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
                git submodule update --init
                # TODO: move init scripts to a custom command to speed up shell start?
                # why does it install in the current source tree? can it all be moved in the nix store?
                bundle config build.statistics2 --with-cflags=-Wno-error=implicit-int
                bundle
                # TODO: make sure we use local file storage by default in dev env
                cp config/storage.yml-example config/storage.yml
                rm -f config/general.yml
                ln -s "${alaveteli_config_general}" config/general.yml
                rm -f config/database.yml
                ln -s "${rails_db_conf_file}" config/database.yml
                #
                # The env is now ready
                #
                figlet -f roman -w 90 Alaveteli
                echo "Alaveteli core dev env ready"
                echo "The services you need (postgres, redis, rails server...) can be started with 'devenv up'"
                echo "(keep them running in a separate terminal)"
                echo "once devenv up is ready, alaveteli will be running at http://localhost:${railsPort}/"
                echo "useful commands:"
                echo "rails c (no path, just this!)"
                echo "Outgoing emails are here: http://localhost:8025"
              '';

              # this is required to build the pg gem on linux
              env = {
                LD_LIBRARY_PATH =
                  nixpkgs.lib.makeLibraryPath [ pkgs.krb5 pkgs.openldap ];
              };

              processes = {
                # run migrations once postgres is started
                migrate = {
                  exec = "rails db:migrate && rails db:seed";
                  process-compose.depends_on.postgres.condition =
                    "process_healthy";
                };
                init_xapian = {
                  exec = ''
                    cd $DEVENV_ROOT
                    trap 'kill -KILL $(jobs -p); wait; exit 0;' SIGTERM
                    RAILS_ENV=development rake xapian:create_index
                    wait
                  '';
                  process-compose.depends_on.migrate.condition =
                    "process_completed_successfully";
                };
                # start the dev web server after migrations
                web = {
                  exec = "rails server -p ${railsPort}";
                  process-compose.depends_on.init_xapian.condition =
                    "process_completed_successfully";
                };
              };

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
              # alaveteli knows to send email to port 1025 in dev
              # which is the default for mailpit
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

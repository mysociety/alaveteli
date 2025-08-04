{
  description = "Ruby environment for Alaveteli development using devenv.sh";
  # to start the shell:
  # nix develop --no-pure-eval (to setup the dev shell)
  # devenv up (to start pg, redis... services)
  # you're ready to code!


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
          alaveteliGems = pkgs.bundlerEnv {
            name = "gems-for-alaveteli";
            gemdir = ./.;
            ruby = pkgs.ruby_3_4;
            extraConfigPaths = [ "${./.}/gems" ];
            gemset = let gems = import ./gemset.nix;
            in gems // {
              mini_racer = gems.mini_racer // {
                buildInputs = [ pkgs.icu ];
                dontBuild = false;
                NIX_LDFLAGS = "-licui18n";
              };
              libv8-node = let
                noopScript = pkgs.writeShellScript "noop" "exit 0";
                linkFiles = pkgs.writeShellScript "link-files" ''
                  cd ../..

                  mkdir -p vendor/v8/${pkgs.stdenv.hostPlatform.system}/libv8/obj/
                  ln -s "${pkgs.nodejs.libv8}/lib/libv8.a" vendor/v8/${pkgs.stdenv.hostPlatform.system}/libv8/obj/libv8_monolith.a

                  ln -s ${pkgs.nodejs.libv8}/include vendor/v8/include

                  mkdir -p ext/libv8-node
                  echo '--- !ruby/object:Libv8::Node::Location::Vendor {}' >ext/libv8-node/.location.yml
                '';
              in gems.libv8-node // {
                dontBuild = false;
                postPatch = ''
                  cp ${noopScript} libexec/build-libv8
                  cp ${noopScript} libexec/build-monolith
                  cp ${noopScript} libexec/download-node
                  cp ${noopScript} libexec/extract-node
                  cp ${linkFiles} libexec/inject-libv8
                '';
              };
            };
            gemConfig = pkgs.defaultGemConfig // {
              mahoro = attrs: { nativeBuildInputs = [ pkgs.file ]; };
              xapian-full-alaveteli = attrs: {
                nativeBuildInputs = [ pkgs.zlib ];
              };
              statistics2 = attrs: {
                buildFlags = [ "--with-cflags=-Wno-error=implicit-int" ];
              };
            };
          };

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
              packages = with pkgs; [
                alaveteliGems
                alaveteliGems.wrappedRuby
                bundix
                libpqxx
                # node
                nodePackages.yarn
                libsass
                catdoc
                elinks
                figlet # for the text banner in the dev shell
                # file # libmagic
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
                wget
                wv
                # For gem: Nokogiri
                libiconv
                libxml2
                libxslt
                transifex-cli
                # zlib
                # For gem: psych
                libyaml
              ];

              enterShell = ''
                export GIT_DIR=$DEVENV_ROOT/.git
                export GIT_WORK_TREE=$DEVENV_ROOT
                git submodule update --init
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
            }];
          };
        });
    };
}

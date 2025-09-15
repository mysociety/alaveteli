{
  description = "Ruby environment for Alaveteli development using devenv.sh";
  # to start the shell:
  # nix develop --no-pure-eval (to setup the dev shell)
  # devenv up (to start pg, redis... services)
  # you're ready to code!


  inputs = {
    self.submodules = true;
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    # nixpkgs-ruby.inputs = { nixpkgs.follows = "nixpkgs"; };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    {
      self,
      nixpkgs,
      devenv,
      systems,
      ...
    }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      # imports = [ ./package.nix ];
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          ruby = pkgs.ruby_3_4;
        in
        {
          devenv-up = self.devShells.${system}.default.config.procfileScript;
          devenv-test = self.devShells.${system}.default.config.test;
          serverTests = pkgs.testers.runNixOSTest (
            import ./nix/alaveteli-server-test.nix { inherit inputs; }
          );
          default = pkgs.callPackage ./nix/package.nix {
            mkBundleEnv = self.mkBundleEnv;
          };
        }
      );

      # allow the theme flake to override these
      themeGemset = { };
      themeLockfile = null;

      mkBundleEnv = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./nix/bundlerEnv.nix { };
        }
      );
      alaveteliGems = forEachSystem (system: {
        # pass themeGems from the theme's dev env flake
        default = self.outputs.mkBundleEnv.${system}.default {
          themeGemset = self.outputs.themeGemset;
          themeLockfile = self.outputs.themeLockfile;
        };
      });

      packagesForAlaveteli = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # packages required to run alaveteli, in production
          # and for development
          running =
            {
              myGems ? self.alaveteliGems.${system}.default,
            }:
            with pkgs;
            [
              # self.alaveteliGems.${system}.default
              # self.alaveteliGems.${system}.default.wrappedRuby
              myGems
              myGems.wrappedRuby
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
          # additional packages only needed for the dev env
          developing = with pkgs; [
            bundix
            figlet
          ];
        }
      );

      devShells = forEachSystem (
        system:
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
            # THEME_URLS = [ "https://github.com/mysociety/alavetelitheme.git" ];
          });
        in
        {
          # commonModules are exposed here so that each devenv can access
          # the various components and override them
          commonModules = {
            packages =
              self.packagesForAlaveteli.${system}.running { } ++ self.packagesForAlaveteli.${system}.developing;

            enterShell = ''
              export GIT_DIR=$DEVENV_ROOT/.git
              export GIT_WORK_TREE=$DEVENV_ROOT
              git submodule update --init
              # TODO: make sure we use local file storage by default in dev env
              cp config/storage.yml-example config/storage.yml
              rm -f config/general.yml
              ln -s "${alaveteli_config_general}" config/general.yml
              # use the madada config file
              # ln -s ../../dada-core/config/general_dada.yml config/general.yml
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
            # TODO: can we move this to gemConfig instead? we don't need
            # this env var once the gem is built
            env = {
              LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath [
                pkgs.krb5
                pkgs.openldap
              ];
            };

            processes = {
              # run migrations once postgres is started
              migrate = {
                exec = "rails db:migrate && rails db:seed";
                process-compose.depends_on.postgres.condition = "process_healthy";
              };
              init_xapian = {
                exec = ''
                  cd $DEVENV_ROOT
                  trap 'kill -KILL $(jobs -p); wait; exit 0;' SIGTERM
                  RAILS_ENV=development rake xapian:create_index
                  wait
                '';
                process-compose.depends_on.migrate.condition = "process_completed_successfully";
              };
              # start the dev web server after migrations
              web = {
                exec = "rails server -p ${railsPort}";
                process-compose.depends_on.init_xapian.condition = "process_completed_successfully";
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
              initialScript = "CREATE ROLE postgres SUPERUSER; ALTER ROLE postgres WITH LOGIN;";
              listen_addresses = dbHost;
              port = dbPort;
              extensions = extensions: [ ];
            };
            # alaveteli knows to send email to port 1025 in dev
            # which is the default for mailpit
            services.mailpit = {
              enable = true;
            };
            services.redis = {
              enable = true;
            };
          };

          # use this one to develop on core alaveteli
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [ self.devShells.${system}.commonModules ];
          };

          # use this env to develop with some custom theme
          # this should be in the theme repo, as the goal here is to work
          # on the theme itself
          # start it with: nix develop --no-pure-eval .#devWithTheme
          devWithTheme = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              (
                self.devShells.${system}.commonModules
                // {
                  # enterShell = self.devShells.${system}.default.enterShell
                  enterShell = self.devShells.${system}.commonModules.enterShell + "echo booyah";
                  env = self.devShells.${system}.commonModules.env // {
                    FOOENV = "themeON";
                  };
                }
              )
            ];
          };
        }
      );
    };
}

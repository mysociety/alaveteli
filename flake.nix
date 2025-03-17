{
  description = "Ruby environment for Alaveteli development";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-21_11.url = "github:nixos/nixpkgs/nixos-21.11";
  };

  outputs = { self, nixpkgs, nixpkgs-21_11, flake-utils }:

  flake-utils.lib.eachDefaultSystem (
    system: let
      pkgs = import nixpkgs { inherit system; };
      pkgs-21_11 = import nixpkgs-21_11 { inherit system; };

      ruby = pkgs.ruby_3_4;
      postgres = pkgs.postgresql_13;

      node = pkgs.nodejs-18_x;

      icu = pkgs.icu60;
    in
    {
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          ruby
          postgres
          libpqxx

          node
          nodePackages.yarn

          transifex-cli

          mailhog
          pkgs-21_11.redis

          libsass
          gnuplot

          catdoc
          elinks
          file # libmagic
          ghostscript
          icu
          imagemagick
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
          zlib

          # For gem: psych
          libyaml
        ];

        shellHook = ''
          #### PostgreSQL ###
          # PG data directory inside direnv directory
          export PGDATA=$PWD/.pgdata

          # PG Unix socket inside direnv directory
          export PGHOST=$PGDATA

          if [[ ! -d "$PGDATA" ]]; then
            # Create PG data directory if doesn't exist
            initdb
            # Configure it to listen only on the Unix socket
            cat >> "$PGDATA/postgresql.conf" <<-EOF
              listen_addresses = '''
              unix_socket_directories = '$PGHOST'
          EOF
            # Create a database using the name Postgres defaults to
            echo "CREATE DATABASE $USER;" | postgres --single -E postgres
          fi

          ### Ruby ###
          export RUBY_VERSION=${ruby.version}
          export GEM_HOME=$PWD/.bundle/$RUBY_VERSION
          export GEM_PATH=$GEM_HOME
          export PATH=$GEM_HOME/bin:$PATH

          # For xapian-full-alaveteli < 1.4.22.2, see: https://github.com/mysociety/xapian-full/issues/10
          export LIBS="$(${ruby}/bin/ruby -e 'puts RbConfig::CONFIG["LIBRUBYARG"]')"

          # Fix https://github.com/abscondment/statistics2/issues/8
          bundle config build.statistics2 --with-cflags=-Wno-error=implicit-int

          # Fix for early syck versions: https://github.com/ruby/syck/pull/47
          bundle config build.syck --with-cflags=-Wno-incompatible-function-pointer-types
        '';
      };
    }
  );
}

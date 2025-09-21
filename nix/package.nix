{
  stdenvNoCC,
  lib,
  applyPatches,
  git,
  procps,
  ruby,
  postgresql,
  cacert,
  dataDir, # ? "/var/www/alaveteli",
  mkBundleEnv,
}:

let
  pname = "alaveteli";
  # TODO: get this from git?
  version = "0.0.1";
  # TODO: make this a function arg?
  # dataDir = "/var/lib/alaveteli";

  src = applyPatches {
    src = ./..;
    patches = [
      # move xapiandb out of source tree and into /var/lib/alaveteli
      # TODO: how to move it to dataDir?
      ./patches/lib_acts_as_xapian.patch
      ./patches/themes_rake.patch
      ./patches/theme_loader_rb.patch
    ];
    postPatch =
      # bash
      ''
        sed -i -e "s|ruby '3.2.[0-9]\+'|ruby '${ruby.version}'|" Gemfile
        sed -i -e "s|ruby 3.2.[0-9]\+p[0-9]\+|ruby ${ruby.version}|" Gemfile.lock
        rm public/views_cache
      '';
  };

  rubyEnv = mkBundleEnv.default {
    themeGemfile = ../Gemfile_theme;
    themeGemset = import ../gemset_theme.nix;
    themeLockfile = ../Gemfile_theme.lock;
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  buildInputs = [
    git
    rubyEnv
    rubyEnv.wrappedRuby
    rubyEnv.bundler
  ];

  nativeBuildInputs = [
    postgresql
    procps
    cacert
  ];

  # force production env here, as we don't build the package in development
  env.RAILS_ENV = "production";

  buildPhase =
    # bash
    ''
      runHook preBuild

      # redis does not seem to be required to compile assets
      mkdir postgres-work
      initdb -D postgres-work --encoding=utf8
      pg_ctl start -D postgres-work -o "-k $PWD/postgres-work -h '''"
      createuser -h $PWD/postgres-work alaveteli -R -S
      createdb -h $PWD/postgres-work --encoding=utf8 --owner=alaveteli alaveteli_production

      rake DATABASE_URL="postgresql:///alaveteli_production?host=$PWD/postgres-work" assets:precompile
      rake DATABASE_URL="postgresql:///alaveteli_production?host=$PWD/postgres-work" assets:link_non_digest

      ps aux | grep redis

      pg_ctl stop -D postgres-work -m immediate
      rm -r postgres-work

      runHook postBuild
    '';

  installPhase = ''
    cp -R . $out
    rm -rf $out/config/database.yml $out/tmp $out/log
    # dataDir will be set in the module, and the package gets overriden there
    ln -s ${dataDir}/config/general.yml $out/config/general.yml
    ln -s ${dataDir}/config/database.yml $out/config/database.yml
    ln -s ${dataDir}/config/storage.yml $out/config/storage.yml
    ln -s ${dataDir}/tmp $out/tmp
    ln -s ${dataDir}/log $out/log
  '';

  passthru = {
    inherit rubyEnv;
  };

  # TODO: this was to get around a ./result symlink that points to the test runner
  # but why??
  dontCheckForBrokenSymlinks = true;

  meta = with lib; {
    description = "Alaveteli, a Freedom of Information request system for your jurisdiction";
    homepage = "https://alaveteli.org";
    license = licenses.agpl3Plus;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = with maintainers; [ laurents ];
  };
}

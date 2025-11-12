{
  stdenvNoCC,
  lib,
  applyPatches,
  git,
  procps,
  ruby,
  postgresql,
  cacert,
  dataDir,
  pkgs,
  themeGemfile,
  themeLockfile,
  themeGemset,
  themeUrl,
  themeFiles,
}:

let
  pname = "alaveteli";
  # TODO: get this from git?
  version = "0.0.1";

  src = applyPatches {
    # TODO: should the code version be fixed, or just the local src tree?
    src = ./..;
    patches = [
      # move xapiandb out of source tree and into dataDir
      # TODO: these patches hardcode /var/lib/alaveteli, but we should really
      # use cfg.dataDir instead. Maybe use substituteInPlace?
      ./patches/lib_acts_as_xapian.patch
      ./patches/themes_rake.patch
      ./patches/theme_loader_rb.patch
      ./patches/routes_rb.patch
      ./patches/conf_env_prod.patch
    ];
    postPatch =
      # bash
      ''
        sed -i -e "s|ruby '3.2.[0-9]\+'|ruby '${ruby.version}'|" Gemfile
        sed -i -e "s|ruby 3.2.[0-9]\+p[0-9]\+|ruby ${ruby.version}|" Gemfile.lock
        rm public/views_cache
      '';
  };

  # binaries needed by alaveteli's rails/rake... at runtime
  runtimeDeps = [
    rubyEnv.wrappedRuby
    pkgs.git
  ];

  # make rake/rails commands available on the server
  # with the correct gems and dependencies configured
  # Run these with sudo -u alaveteli to allow database connection
  rails =
    pkgs.runCommand "rails-alaveteli"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      # bash
      ''
        mkdir -p $out/bin
        makeWrapper ${rubyEnv}/bin/rails $out/bin/rails-alaveteli \
            --prefix PATH : ${lib.makeBinPath runtimeDeps} \
            --set RAILS_ENV production \
            --chdir '${alaveteli}'
      '';

  rake =
    pkgs.runCommand "rake-alaveteli"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      # bash
      ''
        mkdir -p $out/bin
        makeWrapper ${rubyEnv}/bin/rake $out/bin/rake-alaveteli \
            --prefix PATH : ${lib.makeBinPath runtimeDeps} \
            --set RAILS_ENV production \
            --chdir '${alaveteli}'
      '';

  rubyEnv = pkgs.callPackage ./bundlerEnv.nix {
    inherit themeGemfile themeLockfile themeGemset;
  };
  # TODO: move package.nix under the module, as we don't need the package
  # by itself, then we can access config more easily to grab the general conf
  # during buildPhase (but what happens in dev env if we don't want the theme?)
  settingsFormat = pkgs.formats.yaml { };
  alaveteliConfig = settingsFormat.generate "general.yml" ({
    THEME_URLS = [
      themeUrl
    ];
  });
  storageConfig = settingsFormat.generate "storage.yml" {
    local = {
      service = "Disk";
      root = "storage/local";
    };
    raw_emails = {
      service = "Disk";
      # can't use Rails.root here, as it would end up in /nix/store
      root = "storage/raw_emails";
    };
    attachments = {
      service = "Disk";
      root = "storage/attachments";
    };
  };

  themeNameFromUrl =
    with lib.strings;
    (builtins.head (splitString "." (lib.last (splitString "/" themeUrl))));

  alaveteli = stdenvNoCC.mkDerivation {
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

    # copy theme files into the main rails tree before building the package,
    # as they are needed for asset precompilation. Without this, the site
    # builds and runs, but the theme CSS is not applied, for instance.
    preBuild =
      lib.optional (themeFiles != null)
        # bash
        ''
          mkdir -p lib/themes/${themeNameFromUrl}/
          cp -R ${themeFiles}/* lib/themes/${themeNameFromUrl}/
        '';

    buildPhase =
      # bash
      ''
        runHook preBuild

        # redis does not seem to be required to compile assets,
        # but rails expects a database, although it does not seem
        # to actually use it
        mkdir postgres-work
        initdb -D postgres-work --encoding=utf8
        pg_ctl start -D postgres-work -o "-k $PWD/postgres-work -h '''"
        createuser -h $PWD/postgres-work alaveteli -R -S
        createdb -h $PWD/postgres-work --encoding=utf8 --owner=alaveteli alaveteli_production

        # we need to have access to the theme here in config/general.yml, otherwise
        # theme assets can't be found
        cat ${alaveteliConfig} > config/general.yml
        cat ${storageConfig} > config/storage.yml
        echo "BUILDING PKG"
        pwd
        command -v rake
        echo $PATH
        rake ALAVETELI_NIX_BUILD_PHASE=1 DATABASE_URL="postgresql:///alaveteli_production?host=$PWD/postgres-work" assets:precompile
        rake ALAVETELI_NIX_BUILD_PHASE=1 DATABASE_URL="postgresql:///alaveteli_production?host=$PWD/postgres-work" assets:link_non_digest

        rm config/general.yml
        rm config/storage.yml

        # remove some useless files
        rm config/*example

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
      inherit rails rake rubyEnv;

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
  };
in
alaveteli

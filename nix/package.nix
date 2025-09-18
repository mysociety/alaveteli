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
    postPatch =
      # bash
      ''
        sed -i -e "s|ruby '3.2.[0-9]\+'|ruby '${ruby.version}'|" Gemfile
        sed -i -e "s|ruby 3.2.[0-9]\+p[0-9]\+|ruby ${ruby.version}|" Gemfile.lock
        rm public/views_cache
      '';
  };

  rubyEnv = mkBundleEnv.default {
    themeGemset = { };
    themeLockfile = ../Gemfile.lock;
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

  buildPhase = ''
    # replace the default call to configure/make/make install
    echo "TODO: precompile assets, etc..."
  '';
  installPhase = ''
    cp -R . $out
    rm -rf $out/config/database.yml $out/tmp $out/log
    # dataDir will be set in the module, and the package gets overriden there
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

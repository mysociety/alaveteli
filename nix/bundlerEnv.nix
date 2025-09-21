{
  config,
  lib,
  pkgs,
  ...
}:
{
  default =
    {
      # pass 3 files that represent the *entire* set of gems used
      # by the theme, ie. core alaveteli + theme gems
      themeGemfile ? null,
      themeLockfile ? null,
      themeGemset,
    }:
    pkgs.bundlerEnv {
      name = "gems-for-alaveteli";
      gemdir = ./..;
      ruby = pkgs.ruby_3_4;
      extraConfigPaths = [ "${./..}/gems" ];
      lockfile = themeLockfile;
      gemfile = themeGemfile;
      gemset =
        let
          gems = if themeGemset != null then themeGemset else import ../gemset.nix;
        in
        gems
        # add build dependencies for gems alaveteli uses
        // {
          mini_racer = gems.mini_racer // {
            buildInputs = [ pkgs.icu ];
            dontBuild = false;
            NIX_LDFLAGS = "-licui18n";
          };
          libv8-node =
            let
              noopScript = pkgs.writeShellScript "noop" "exit 0";
              linkFiles = pkgs.writeShellScript "link-files" ''
                cd ../..

                mkdir -p vendor/v8/${pkgs.stdenv.hostPlatform.system}/libv8/obj/
                ln -s "${pkgs.nodejs.libv8}/lib/libv8.a" vendor/v8/${pkgs.stdenv.hostPlatform.system}/libv8/obj/libv8_monolith.a

                ln -s ${pkgs.nodejs.libv8}/include vendor/v8/include

                mkdir -p ext/libv8-node
                echo '--- !ruby/object:Libv8::Node::Location::Vendor {}' >ext/libv8-node/.location.yml
              '';
            in
            gems.libv8-node
            // {
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
        xapian-full-alaveteli = attrs: { nativeBuildInputs = [ pkgs.zlib ]; };
        statistics2 = attrs: {
          buildFlags = [ "--with-cflags=-Wno-error=implicit-int" ];
        };
      };
    };
}

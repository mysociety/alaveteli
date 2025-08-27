{ config, lib, pkgs, ... }: {
  default = { themeGemset, themeLockfile }:
    pkgs.bundlerEnv {
      name = "gems-for-alaveteli";
      gemdir = ./.;
      ruby = pkgs.ruby_3_4;
      extraConfigPaths = [ "${./.}/gems" ];
      lockfile = themeLockfile;
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
      } // builtins.trace themeGemset themeGemset;
      gemConfig = pkgs.defaultGemConfig // {
        mahoro = attrs: { nativeBuildInputs = [ pkgs.file ]; };
        xapian-full-alaveteli = attrs: { nativeBuildInputs = [ pkgs.zlib ]; };
        statistics2 = attrs: {
          buildFlags = [ "--with-cflags=-Wno-error=implicit-int" ];
        };
      };
      # preBuild = if themeGems != { } then
    };
}

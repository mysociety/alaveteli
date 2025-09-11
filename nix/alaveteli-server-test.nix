# run tests with `nix -L build  --no-pure-eval .#serverTests`
{
  name = "Alaveteli server test";

  nodes.server =
    { pkgs, ... }:
    {
      imports = [ ./module.nix ];
      networking = {
        firewall = {
          allowedTCPPorts = [ 80 ];
        };
      };

      environment.etc."railsPass".text = ''
        supersecurepassword
      '';

      # environment.systemPackages = [ pkgs.git ];
      # can't find this service, how to add it?
      services.alaveteli = {
        enable = true;
        domainName = "server";
        database.passwordFile = "/etc/railsPass";
        # TEMP while hydra rebuilds postgres
        # database.createLocally = false;
      };
    };

  testScript =
    # python
    ''
      start_all()
      testserver.wait_for_unit("alaveteli-puma.service")
      testserver.succeed("curl -ks4 https://testserver/ | grep -o 'h1.*Alaveteli'")
      testserver.succeed("curl -ks6 https://testserver/ | grep -o 'h1.*Alaveteli'")
    '';
}

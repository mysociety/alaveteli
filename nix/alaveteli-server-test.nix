# run tests with `nix -L build  --no-pure-eval .#serverTests`
{
  name = "Alaveteli server test";

  nodes.server = { pkgs, ... }: {
    imports = [ ./module.nix ];
    networking = { firewall = { allowedTCPPorts = [ 80 ]; }; };

    environment.etc."railsPass".text = ''
      supersecurepassword
    '';

    # environment.systemPackages = [ pkgs.git ];
    # can't find this service, how to add it?
    services.alaveteli = {
      enable = true;
      domainName = "server";
      database.passwordFile = "/etc/railsPass";
    };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("alaveteli-puma.service")
    server.succeed("curl -s4 http://server/ | grep -o 'h1.*Alaveteli'")
    server.succeed("curl -s6 http://server/ | grep -o 'h1.*Alaveteli'")
  '';
}

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
      domainName = "alaveteli.test";
      database.passwordFile = "/etc/railsPass";
    };
  };

  # nodes.client = { pkgs, ... }: {
  #   environment.systemPackages = with pkgs; [ curl ];
  # };

  testScript = ''
    start_all()
    server.wait_for_unit("default.target")
    server.wait_for_unit("alaveteli-puma.service")
    server.succeed("curl http://server/ | grep -o Alaveteli")
  '';
}

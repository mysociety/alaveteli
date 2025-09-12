# run tests with `nix -L build  --no-pure-eval .#serverTests`
{
  name = "Alaveteli server test";

  nodes.testserver =
    {
      nodes,
      config,
      pkgs,
      ...
    }:
    let
      domain = "alaveteli.test";
    in
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

      security.acme = {
        # TODO: make acme use a test provider
        defaults.email = "test@${domain}";
        defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
        acceptTerms = true;
      };

      # environment.systemPackages = [ pkgs.git ];
      # can't find this service, how to add it?
      services.alaveteli = {
        enable = true;
        domainName = domain;
        database.passwordFile = "/etc/railsPass";
        # TEMP while hydra rebuilds postgres
        # database.createLocally = false;
      };

      environment.systemPackages = [
        # for debugging tests, remove it
        pkgs.net-tools
        pkgs.ripgrep
      ];
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

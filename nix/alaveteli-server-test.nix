# run tests with `nix -L build  --no-pure-eval .#serverTests`
# or `nix -L build  --no-pure-eval .#serverTests.driverInteractive`
{ inputs, ... }:
{
  name = "Alaveteli server test";

  nodes.testserver =
    {
      nodes,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domain = "alaveteli.test";
      tls-cert = pkgs.runCommand "selfSignedCerts" { buildInputs = [ pkgs.openssl ]; } ''
        mkdir -p $out
        openssl req -x509 \
          -subj '/CN=pleroma.nixos.test/' -days 49710 \
          -addext 'subjectAltName = DNS:${domain}' \
          -keyout "$out/key.pem" -newkey ed25519 \
          -out "$out/cert.pem" -noenc
      '';
    in
    {
      imports = [
        (import ./module.nix inputs.self {
          inherit
            config
            inputs
            lib
            pkgs
            ;
        })
      ];
      networking = {
        firewall = {
          allowedTCPPorts = [ 80 ];
        };
      };

      environment.etc."railsPass".text = ''
        supersecurepassword
      '';

      security.pki.certificateFiles = [
        "${tls-cert}/cert.pem"
      ];

      services.geoipupdate.enable = false;

      services.alaveteli = {
        enable = true;
        domainName = domain;
        database.passwordFile = "/etc/railsPass";
        database.createLocally = true;
        database.backup.enable = false;
        sslCertificate = "${tls-cert}/cert.pem";
        sslCertificateKey = "${tls-cert}/key.pem";
        geoipLicenseKey = "/dev/null";
        theme = {
          url = "https://github.com/mysociety/alavetelitheme.git";
        };
      };

      networking.extraHosts = ''
        127.0.0.1 ${domain}
        ::1 ${domain}
      '';

      environment.systemPackages =
        let
          # check that the server can receive a response to a magic email
          sendTestResponse =
            pkgs.writeScriptBin "send-mail-to-postmaster"
              # python
              ''
                #!${pkgs.python3.interpreter}
                import smtplib
                import ssl

                ctx = ssl.create_default_context()

                with smtplib.SMTP('${domain}', timeout=10) as smtp:
                  smtp.ehlo()
                  smtp.starttls(context=ctx)
                  smtp.ehlo()
                  smtp.sendmail(
                    'root@alaveteli.remote', # from
                    'postmaster@${domain}', # to
                    'Subject: Test Response\n\nTest data.'
                  )
                  smtp.quit()
              '';
        in
        [
          sendTestResponse
          # for debugging tests, remove it
          pkgs.net-tools
          pkgs.ripgrep
        ];
    };

  testScript =
    # python
    ''
      start_all()
      testserver.wait_for_unit("postfix.service")
      testserver.wait_for_unit("opendkim.service")
      testserver.wait_for_unit("dovecot.service")
      testserver.wait_for_unit("rspamd.service")
      testserver.wait_for_unit("alaveteli-puma.service")
      testserver.wait_for_open_port(80)
      testserver.wait_for_open_port(443)
      testserver.wait_for_open_port(25)
      testserver.wait_for_open_port(587)
      testserver.wait_for_open_port(110)
      testserver.succeed("send-mail-to-postmaster")
      testserver.succeed("curl -ks4 https://testserver/ | grep -o 'h1.*Alaveteli'")
      testserver.succeed("curl -ks6 https://testserver/ | grep -o 'h1.*Alaveteli'")
      testserver.succeed("rails-alaveteli boot")
    '';
}

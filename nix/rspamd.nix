{
  config,
  inputs,
  ...
}:
let
  cfg = config.services.alaveteli;
in
{
  # use rspamd service definition from our PR
  disabledModules = [ "services/mail/rspamd.nix" ];
  imports = [
    "${inputs.nixpkgsrspamd}/nixos/modules/services/mail/rspamd.nix"
  ];
  services.rspamd = {
    enable = true;
    locals = {
      "actions.conf".text = ''
        reject = 35; # default is 15, we do not want to reject for now
        add_header = 6; # default is 6
        greylist = 4; # Apply greylisting when reaching this score (will emit `soft reject action`)
      '';

      "country_bl.map".text = ''
        CN
        RU
      '';

      "milter_headers.conf".text = ''
        # Add "extended Rspamd headers" (default false) (enables x-spamd-result, x-rspamd-server & x-rspamd-queue-id routines)
        # (only for incoming emails)
        extended_spam_headers = true;
      '';

      "multimap.conf".text = ''
              # add points to email from countries listed in country_bl
        COUNTRY_BL {
                type = "country";
                map = "''${LOCAL_CONFDIR}/local.d/country_bl.map";
                score = 6;
                description = "List of countries with heavy spam usage";
        }
      '';

      "redis.conf".text = ''
        write_servers = "localhost";
        read_servers = "localhost";
      '';
    };
    workers = {
      controller = { };
      normal = {
        type = "normal";
        bindSockets = [ "localhost:11333" ];
      };

      rspamd_proxy = {
        bindSockets = [
          "localhost:11332"
        ];
        type = "rspamd_proxy";
        count = 2;
        extraConfig = ''
          # https://www.rspamd.com/doc/tutorials/quickstart.html#using-of-milter-protocol-for-rspamd--16
          milter = yes; # Enable milter mode
          timeout = 120s; # Needed for Milter usually
          upstream "local" {
            default = yes; # Self-scan upstreams are always default
            self_scan = yes; # Enable self-scan
          }
          max_retries = 5; # How many times master is queried in case of failure
          discard_on_reject = false; # Discard message instead of rejection
          quarantine_on_reject = false; # Tell MTA to quarantine rejected messages
          spam_header = "X-Spam"; # Use the specific spam header
          reject_message = "Spam message rejected"; # Use custom rejection message
        '';
      };
    };
  };

}

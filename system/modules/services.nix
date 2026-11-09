{pkgs, ...}: {
  services = {
    acpid.enable = true;
    fwupd.enable = true;
    upower.enable = true;
    logind.settings.Login.HandleLidSwitch = "ignore";
    gvfs.enable = true;
    tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = [
        "--accept-dns=true"
        "--exit-node-allow-lan-access=true"
      ];
    };
    v2raya = {
      enable = true;
      package = pkgs.callPackage ../packages/v2raya.nix {};
    };

    resolved = {
      enable = true;
      settings.Resolve = {
        DNS = ["127.0.0.1:5335"];
        DNSSEC = "allow-downgrade";
        Domains = ["~."];
        FallbackDNS = [];
        DNSOverTLS = "false";
      };
    };

    smartdns = {
      enable = true;
      bindPort = 5335;
      settings = {
        bind = [
          "127.0.0.1:5335"
          "[::1]:5335"
        ];
        cache-size = 8192;
        prefetch-domain = true;
        response-mode = "fastest-response";
        force-no-CNAME = true;

        server-https = [
          # Prefer censorship-resistant public resolvers.
          "https://cloudflare-dns.com/dns-query -host-ip 1.1.1.1"
          "https://dns.google/dns-query -host-ip 8.8.8.8"

          # Keep DNS usable when the primary DoH endpoints are unreachable.
          "https://dns.alidns.com/dns-query -host-ip 223.5.5.5 -fallback"
          "https://doh.pub/dns-query -host-ip 1.12.12.12 -fallback"
        ];
      };
    };

    openssh = {
      enable = true;
      allowSFTP = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    sshd.enable = true;

    printing = {
      enable = true;
      drivers = [pkgs.epson-escpr];
    };

    postgresql.enable = false;
  };
  # The manager stops its core before systemd signals remaining processes.
  systemd.services.v2raya.serviceConfig.KillMode = "mixed";
}

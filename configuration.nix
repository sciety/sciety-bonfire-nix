{ config, pkgs, ... }:

{
  imports =
    [
    ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  time.timeZone = "europe/london";

  boot = {
   kernelPackages = pkgs.linuxPackages_6_1;
   supportedFilesystems = [ "btrfs"];

   loader.grub = {
    enable = true;
    version = 2;
    forceInstall = true;
    device = "/dev/sda";
   };
  };

  bonfire = {
    flavor = "social";
    version = "1.0.0-rc.2.3";
    hostname = "dev-discussions.sciety.org";
    mail-from = "bonfire-admin@sciety.org";
    mail-backend = "sendgrid";
  };

  # This will add hetzner.yml to the nix store
  # You can avoid this by adding a string to the full path instead, i.e.
  # sops.defaultSopsFile = "/root/.sops/secrets/example.yaml";
  sops.defaultSopsFile = ./secrets/hetzner.yaml;

  # This will automatically import SSH keys as age keys
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # This is using an age key that is expected to already be in the filesystem
  sops.age.keyFile = "/root/.config/sops/age/keys.txt";

  # This will generate a new key if the key specified above does not exist
  sops.age.generateKey = false;

  # This is the actual specification of the secrets.
  sops.secrets."bonfire/mail_key" = {};
  sops.secrets."bonfire/secret_key_base" = {};
  sops.secrets."bonfire/signing_salt" = {};
  sops.secrets."bonfire/encryption_salt" = {};

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "bonfire-admin@sciety.org";
  services.nginx = {
    enable = true;
    virtualHosts = {
      "dev-discussions.sciety.org" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:4000";
          extraConfig =
            # Taken from https://www.nginx.com/resources/wiki/start/topics/examples/full/
            # Those settings are used when proxies are involved
            "proxy_redirect          off;" +
            "proxy_set_header        Host $host;" +
            "proxy_set_header        X-Real-IP $remote_addr;" +
            "proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;" +
            "proxy_http_version      1.1;" +
            "proxy_cache_bypass      $http_upgrade;" +
            "proxy_set_header        Upgrade $http_upgrade;" +
            "proxy_set_header        Connection \"upgrade\";" +
            "proxy_set_header        X-Forwarded-Proto $scheme;" +
            "proxy_set_header        X-Forwarded-Host  $host;";
        };
      };
    };
  };

  systemd.services.docker-bonfire = {
    requires = [ "docker-bonfire.service" ];
    after = [ "docker-bonfire.service" ];
  };

  networking = {
   hostName = "nixos-vm";
   useDHCP = false;

   interfaces = {
    eth0.useDHCP = true;
  };

  firewall = {
   enable = true;
   allowedTCPPorts = [ 80 443 ];
   allowedUDPPorts = [];
   };
  };

  nix = {
     gc = {
       automatic = true;
       dates = "monthly";
       options = "--delete-older-than 30d";
       };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = false;
  };

  services.fail2ban.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbtpVOYTYF0aCPNpQSUoU7efLH13RwCwiN4rmhl3RQN mark.williams@protonmail.com"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPLo9gQ9VwhKuaBSL84liznZT1Eov71DkcKqZFJZKgfgo+Lug4mf03WTrp5/BJEYuPjj4P4RAkakX/5NjHf7ypBr+sBBo02HH5AgJB2GRhcDVJTiJwaG7ghl5kN+lDk+yD5YWckSVHgMVmukEtEf5P4EH4bRfIBaF76md1qt5cG6/NXGDpvkTE1y+40OdjI6dj1/4StktaQiqPI09zPMFbJewxR2Npiua5q1PDXSi677JAeO2FMv16wJpaJXczkSwuQIv5sf3/DgYi/ZpAuzdm4+nlj/1xKTH0fVAdP+gfwDKiOIuIYqjata2+MHgVkkJyIGlgOmTZPWRY1VuooAWdIAKZajpNX5sGePD1tzuO9yOiKTJkq2Q3W3V7xFRFEhAjMUid3/5Q9HZ7Ymms+4lz1tRu9aJj8hKVdiL70L6Qk2zi7uGgbZaKym69B5O3qyDcMT/bX/83pEhL9tQ2WsSwQD7ISPgw1V8+iKgh76I0IBkNT3tUiXeD+EYjutSCYXSajdfk4eMfuNgA+HMZKEyMhfta+SxfRObGgHhusjiiuhn5Tak2vbLf1DG8+2cJE8LTHtWhm5PBgBsTQS5EPVh5HONRy2Ya+KTzNMOskmkT/FZESKNuCWqb+GOEmx2VXzC0xW/GBnDiEfwxV3olcHOrX88JeBbzRTDcovfWUJzKZQ== goodoldpaul@autistici.org"
  ];

  users.users.mark.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbtpVOYTYF0aCPNpQSUoU7efLH13RwCwiN4rmhl3RQN mark.williams@protonmail.com"
  ];

  users.users.giacomo.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPLo9gQ9VwhKuaBSL84liznZT1Eov71DkcKqZFJZKgfgo+Lug4mf03WTrp5/BJEYuPjj4P4RAkakX/5NjHf7ypBr+sBBo02HH5AgJB2GRhcDVJTiJwaG7ghl5kN+lDk+yD5YWckSVHgMVmukEtEf5P4EH4bRfIBaF76md1qt5cG6/NXGDpvkTE1y+40OdjI6dj1/4StktaQiqPI09zPMFbJewxR2Npiua5q1PDXSi677JAeO2FMv16wJpaJXczkSwuQIv5sf3/DgYi/ZpAuzdm4+nlj/1xKTH0fVAdP+gfwDKiOIuIYqjata2+MHgVkkJyIGlgOmTZPWRY1VuooAWdIAKZajpNX5sGePD1tzuO9yOiKTJkq2Q3W3V7xFRFEhAjMUid3/5Q9HZ7Ymms+4lz1tRu9aJj8hKVdiL70L6Qk2zi7uGgbZaKym69B5O3qyDcMT/bX/83pEhL9tQ2WsSwQD7ISPgw1V8+iKgh76I0IBkNT3tUiXeD+EYjutSCYXSajdfk4eMfuNgA+HMZKEyMhfta+SxfRObGgHhusjiiuhn5Tak2vbLf1DG8+2cJE8LTHtWhm5PBgBsTQS5EPVh5HONRy2Ya+KTzNMOskmkT/FZESKNuCWqb+GOEmx2VXzC0xW/GBnDiEfwxV3olcHOrX88JeBbzRTDcovfWUJzKZQ== goodoldpaul@autistici.org"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIySsOgdceI/vD3dpY9NfViA25SU71jn0Y6rPMmNbJgv goodoldpaul@autistici.org"
  ];

  users.users.mark = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    initialPassword = "test";
  };

  users.users.giacomo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    initialPassword = "test";
  };

  system.stateVersion = "23.11";
}

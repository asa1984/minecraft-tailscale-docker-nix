{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        papermc = pkgs.papermc.overrideAttrs {
          buildPhase = ''
            cat > minecraft-server << EOF
            #!${pkgs.bash}/bin/sh
            exec ${pkgs.jdk20_headless}/bin/java \$@ -jar $out/share/papermc/papermc.jar nogui
          '';
        };
        startup = ''
          ${pkgs.tailscale}/bin/tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock --socks5-server=localhost:1080 &
          ${pkgs.tailscale}/bin/tailscale up --authkey=$TAILSCALE_AUTH_KEY --hostname=$TAILSCALE_HOSTNAME
          ${papermc}/bin/minecraft-server -DsocksProxyHost=localhost -DsocksProxyPort=1080
        '';
      in {
        packages = rec {
          minecraft-tailscale-docker-nix = pkgs.dockerTools.buildImage {
            name = "minecraft-tailscale-docker-nix";
            tag = "latest";
            runAsRoot = ''
              mkdir -p /var/run/tailscale /var/lib/tailscale /var/cache/tailscale
            '';
            config = {
              Cmd = [
                "${pkgs.bash}/bin/sh"
                "-c"
                startup
              ];
              WorkingDir = "/server";
            };
          };
          default = minecraft-tailscale-docker-nix;
        };
      }
    );
}

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
        startup = ''
          /bin/tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock --socks5-server=localhost:1080 &
          /bin/tailscale up --authkey=$TAILSCALE_AUTH_KEY --hostname=$TAILSCALE_HOSTNAME
          /bin/minecraft-server -DsocksProxyHost=localhost -DsocksProxyPort=1080
        '';
      in {
        packages = rec {
          minecraft-tailscale-docker-nix = pkgs.dockerTools.buildImage {
            name = "minecraft-tailscale-docker-nix";
            tag = "latest";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = with pkgs; [
                tailscale
                papermc
              ];
              pathsToLink = ["/bin"];
            };
            runAsRoot = ''
              mkdir -p /var/run/tailscale /var/lib/tailscale /var/cache/tailscale
            '';
            config = {
              Cmd = [
                "${pkgs.bash}/bin/bash"
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

image_name="minecraft-tailscale-docker-nix"

rm result
if [ "$(docker images -q $image_name 2> /dev/null)" ]; then
    docker image rm minecraft-tailscale-docker-nix:latest
fi
nix build
docker load < result

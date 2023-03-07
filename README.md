# nix___stacks
Collection of nix declarative containers stacks


These configs are meant to be used with [extra-container](https://github.com/erikarvstedt/extra-container), which can run declarative NixOS containers like imperative containers, without system rebuilds.

start a container with:
```
sudo extra-container create --start <<EOF
$(cat wp.nix)
EOF
```

useful commands:
```
sudo nixos-container root-login <name>  
sudo extra-container destroy <name>
```


Stacks List:

blogging:
- wordpress


TODO:
- add another treafik subdomain for nix containers. Currently it uses .docker.localdev

- to run a nix stack in a current config disable
/docker/stacks/traefik-portainer/
```
sudo docker-compose -f traefik.yaml down
```

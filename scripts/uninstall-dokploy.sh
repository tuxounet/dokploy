#!/bin/bash
# FROM: https://docs.dokploy.com/docs/core/uninstall

# Remove the docker swarm services created by Dokploy:


docker service remove dokploy dokploy-traefik dokploy-postgres dokploy-redis
docker container remove -f dokploy-traefik
# Remove the docker volumes created by Dokploy:


docker volume remove -f dokploy dokploy-postgres dokploy-redis
# Remove the docker network created by Dokploy:


docker network remove -f dokploy-network
#Docker cleanup to remove leftovers:


docker container prune --force
docker image prune --all --force
docker volume prune --all --force
docker builder prune --all --force
docker system prune --all --volumes --force

#Remove the dokploy files and directories from your server:


sudo rm -rf /etc/dokploy
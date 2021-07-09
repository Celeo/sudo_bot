SSH_TARGET := "do"
IMAGE_FILE := "sudo_bot.image.bin"

default:

build:
  #!/usr/bin/env bash
  set -euxo pipefail
  source .env.prod
  podman build . -t celeo/sudo_bot --build-arg DISCORD_TOKEN=${DISCORD_TOKEN}

image-save:
  rm -f {{IMAGE_FILE}}
  podman image save --output {{IMAGE_FILE}} celeo/sudo_bot

deploy: build image-save
  rsync -avz --progress {{IMAGE_FILE}} {{SSH_TARGET}}:/srv/sudo_bot.image

#!/bin/bash -e

# get latest docker compose released tag
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
BIN_FILE="/usr/local/bin/docker-compose"
COMPLETION_FILE="/etc/bash_completion.d/docker-compose"

CURRENT_VERSION=$(docker-compose --version | sed -n 's|.*\(v[0-9].*\)|\1|p;')

if [ "$CURRENT_VERSION" = "$COMPOSE_VERSION" ] && [ "$1" != "force" ] ; then
  echo "INFO: docker-composer version $COMPOSE_VERSION already installed"
  exit 0
fi

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o "${BIN_FILE}"
sudo chmod +x "${BIN_FILE}"

# # Install docker-compose bash completion
# sudo curl -L "https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose" -o "${COMPLETION_FILE}"

# Output compose version
docker-compose -v

exit 0

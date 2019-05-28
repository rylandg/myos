#!/bin/bash -eu

die () {
    echo >&2 "$@"
    exit 1
}

login () {
    eval $(aws ecr get-login --no-include-email)
}

enforceArgs () {
  if [ "$1" -lt $2 ]; then
    echo "Minimum of $2 arguments required for attach/build/create"
    exit 1
  fi
}

getAccountId() {
  accountQuoted=$(aws sts get-caller-identity --output=json | jq '.Account')
  temp="${accountQuoted%\"}"
  temp="${temp#\"}"
  echo "$temp"
}

if [ "$#" -lt 1 ]; then
    die "Minimum of 1 arguments required for MyOS"
fi

COMMAND=$1
USER_DEFAULT=${DEFAULT_USER:-ubuntu}

# For AWS ECR login
if [ $COMMAND = "login" ]; then
  login
elif [ $COMMAND = "init" ]; then
  enforceArgs $# 2
  mkdir $2
  SCRIPT_DIR=$(dirname "$0")
  cp -R $SCRIPT_DIR/zsh $SCRIPT_DIR/vim $SCRIPT_DIR/tmux $SCRIPT_DIR/.gitignore $SCRIPT_DIR/docker-compose.yml $2
  exit 0
# Builds the MYOS container
elif [ $COMMAND = "build" ]; then
  enforceArgs $# 2
  docker build --build-arg DEFAULT_USER=$2 -t myos:latest .
  exit 0
elif [ $COMMAND = "connect" ]; then
  SOCKET=$(docker-compose port myos 22)
  PORT="$(cut -d':' -f2 <<< $SOCKET)"
  shift 1
  SSH_PARAMS="$@ -Y -tt -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $PORT"
  ssh $SSH_PARAMS $USER_DEFAULT@localhost
  exit 0
elif [ $COMMAND = "create" ]; then
  enforceArgs $# 2
  if [ "$#" -eq 3 ]; then
    NAME=$2 TAG=$3 docker-compose up -d
  else
    NAME=$2 docker-compose up -d
  fi
  exit 0
elif [ $COMMAND = "restart" ]; then
  enforceArgs $# 2
  if [ "$#" -eq 3 ]; then
    docker stop $2 && docker rm $_
    NAME=$2 TAG=$3 docker-compose up -d
  else
    docker stop $2 && docker rm $_
    NAME=$2 TAG=latest docker-compose up -d
  fi

  exit 0
elif [ $COMMAND = "remove" ]; then
  enforceArgs $# 2
  docker stop $2 && docker rm $_
  exit 0
elif [ $COMMAND = "push" ]; then
  login
  enforceArgs $# 2
  ACCOUNT_ID=$(getAccountId)
  TAG=$2
  docker tag myos:$TAG $ACCOUNT_ID.dkr.ecr.us-west-1.amazonaws.com/myos:$TAG
  docker push $ACCOUNT_ID.dkr.ecr.us-west-1.amazonaws.com/myos:$TAG
  exit 0
elif [ $COMMAND = "pull" ]; then
  login
  enforceArgs $# 2
  TAG=$2
  ACCOUNT_ID=$(getAccountId)
  docker pull $ACCOUNT_ID.dkr.ecr.us-west-1.amazonaws.com/myos:$TAG
  docker tag $ACCOUNT_ID.dkr.ecr.us-west-1.amazonaws.com/myos:$TAG myos:$TAG
  exit 0
elif [ $COMMAND = "commit" ]; then
  enforceArgs $# 3
  NAME=$2
  TAG=$3
  docker commit $NAME myos:$TAG
  exit 0
fi

echo "$COMMAND" not recognized!
exit 1

#!/bin/sh -e -u

MYOS_USER="ubuntu"

initHelp="init <envName> [options]"
createHelp="create <envName> [options]"
connectHelp="connect <envName> [options]"
removeHelp="remove <envName> [options]"
restartHelp="restart <envName> [options]"

die () {
    echo >&2 "$@"
    exit 1
}

unknownCommand () {
  echo "$1" not recognized!
  exit 1
}

enforceArgs () {
  if [ "$1" -lt $2 ]; then
    echo "Minimum of $2 arguments required for $3"
    exit 1
  fi
}

enforceArgs $# 1 "MyOS"

command=$1
# cross-platform dir resolution
myosPath="$( cd "$(dirname  "${BASH_SOURCE[0]}")" ; pwd -P )"
# follows symlink
scriptName="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
scriptPath="$myosPath/$scriptName"

if [ $command = "init" ]; then
  enforceArgs $# 2 $initHelp
  mkdir $2
  cp -r $myosPath/templates/. $2/
elif [ $command = "build" ]; then
  tag=${3:-latest}
  docker build -t myos:$tag .
elif [ $command = "create" ]; then
  enforceArgs $# 2 $createHelp
  args="COMPOSE_PROJECT_NAME=$2"
  if [ "$#" -ge 3 ]; then
    args="$args NAME=$3"
  fi
  if [ "$#" -ge 4 ]; then
    args="$args TAG=$4"
  fi
  export $args && docker-compose up -d
elif [ $command = "remove" ]; then
  enforceArgs $# 2 $removeHelp
  args="COMPOSE_PROJECT_NAME=$2"
  export $args && docker-compose down
elif [ $command = "restart" ]; then
  enforceArgs $# 2 $restartHelp
  args="COMPOSE_PROJECT_NAME=$2"
  if [ "$#" -ge 3 ]; then
    args="$args NAME=$3"
  fi
  if [ "$#" -ge 4 ]; then
    args="$args TAG=$4"
  fi
  export $args && docker-compose down
  export $args && docker-compose up -d
elif [ $command = "connect" ]; then
  enforceArgs $# 2 $connectHelp
  socket=$(docker port "$2_myos_1" 22)
  port="$(cut -d':' -f2 <<<$socket)"
  shift 2
  sshArgs="$@ -Y -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $port"
  ssh $sshArgs $MYOS_USER@localhost
  exit 0
else
  unknownCommand $command
fi

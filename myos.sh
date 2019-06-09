#!/bin/sh -eu
#title        :myos.sh
#description  :Develop and share terminal environments
#author       :rylandg
#github       :https://github.com/rylandg/myos
#========================================================

# Declaring environment variable such as :
# - MYOS_DIR : MyOS ssh keys location.
# - MYOS_USER : Name of the environment's user.
# - SUDO : Check if sudo is needed to run docker.
MYOS_DIR=~/.myos
MYOS_USER="ubuntu"
SUDO=$(if docker info 2>&1 | grep "permission denied" >/dev/null; then echo "sudo -E"; fi)

# Commands descriptions
initHelp="init <envName> [options]"
createHelp="create <envName> [options]"
connectHelp="connect <envName> [options]"
removeHelp="remove <envName> [options]"
restartHelp="restart <envName> [options]"

# What to do if there is an error
die () {
    echo >&2 "$@"
    exit 1
}

# Generate an SSH key and add it to the authorized keys
addAuthorizedKey () {
    if [ ! -f $MYOS_DIR/authorized_keys ]; then
        mkdir -p $MYOS_DIR
        ssh-keygen -f $MYOS_DIR/myos-key -t rsa -N ''
        cp $MYOS_DIR/myos-key.pub $MYOS_DIR/authorized_keys
    fi
    ssh-add $MYOS_DIR/myos-key
}

unknownCommand () {
    echo "$1" not recognized!
    exit 1
}

# Check if the number of given arguments is correct
enforceArgs () {
    if [ "$1" -lt $2 ]; then
        echo "Minimum of $2 arguments required for $3"
        exit 1
    fi
}

enforceArgs $# 1 "MyOS"

# Set command :
# - Example : "myos create" -> set the command to "create".
command=$1

# Set the path to myos.sh
myosPath="$( cd "$(dirname  "$0")" ; pwd -P )"

# Set the script name and its path
scriptName="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
scriptPath="$myosPath/$scriptName"

# Declaring commands :
# - Init : Creates the initial templates that the default docker-compose.yml expects.
# - Build : Build the official MyOS image.
# - Create : Generate ssh key and run docker-compose up -d from the current directory.
# - Remove : Remove a running MyOS environment.
# - Restart : Restart a previously created MyOS environment.
# - Connect : Connects to a previously created MyOS environment
if [ $command = "init" ]; then
    enforceArgs $# 2 $initHelp
    mkdir $2
    cp -r $myosPath/templates/. $2/
elif [ $command = "build" ]; then
    tag=${3:-latest}
    docker build -t myos:$tag .
elif [ $command = "create" ]; then
    enforceArgs $# 2 $createHelp
    addAuthorizedKey
    args="COMPOSE_PROJECT_NAME=$2"
    if [ "$#" -ge 3 ]; then
        args="$args NAME=$3"
    fi
    if [ "$#" -ge 4 ]; then
        args="$args TAG=$4"
    fi
    export $args && $SUDO docker-compose up -d
elif [ $command = "remove" ]; then
    enforceArgs $# 2 $removeHelp
    args="COMPOSE_PROJECT_NAME=$2"
    export $args && $SUDO docker-compose down
elif [ $command = "restart" ]; then
    enforceArgs $# 2 $restartHelp
    args="COMPOSE_PROJECT_NAME=$2"
    if [ "$#" -ge 3 ]; then
        args="$args NAME=$3"
    fi
    if [ "$#" -ge 4 ]; then
        args="$args TAG=$4"
    fi
    export $args && $SUDO docker-compose down
    export $args && $SUDO docker-compose up -d
elif [ $command = "connect" ]; then
    enforceArgs $# 2 $connectHelp
    addAuthorizedKey
    socket=$($SUDO docker port "$2_myos_1" 22)
    port="$(echo "$socket" | cut -d':' -f2)"
    shift 2
    sshArgs="$@ -Y -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $port"
    ssh $sshArgs $MYOS_USER@localhost
    exit 0
else
    unknownCommand $command
fi

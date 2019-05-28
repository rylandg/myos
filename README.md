# MyOS - develop and share command line environments

## High Level

Uses Docker + Docker Compose to provide a consistent and reproducible build environment. Base image assumes the minimum while still being useful out of the box.

## Usage

### Assumptions

Everything depends on `myos` base Docker image. This image is available on Dockerhub, but you may also build it using the included Dockerfile.

The default `docker-compose.yml` mounts your host `~/.ssh/authorized_keys` file into the running container. This is what allows the openssh server to authenticate you when you connect. This means you will need an `authorized_keys` file in the correct location with any keys you want to be able to use.

> Ctrl-D is the most sure fire way of getting out of the container

### Clean start

1. Install the CLI

```bash
$ npm install -g myos
```

2. Create a new template project

```bash
$ myos init ./template
$ cd template
```

3. Start the container

```bash
$ myos create fooName
```

4. Connect to the container

```bash
$ myos connect
```

### Advanced start

Assuming you've already installed the tool, my personal configuration can be used to test out MyOS.

1. Clone my personal MyOS config

```bash
$ git clone https://github.com/rylandg/rylandg-myosfiles
```

2. Create a MyOS based on my setup

```bash
$ cd rylandg-myosfiles
$ myos create rysetup
$ myos connect rysetup
```

## Features

* Python 2 and 3
* Vim 8 with clipboard
* Latest Tmux
* Zsh
* XDisplay and xauth support
* Host copy/paste support
* Htop
* Node12
* Fully working colors
* Does not run as PID 1
* Non-root user
* Uses ssh as entry allowing display server and remote usage
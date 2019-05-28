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

## API

### Init
`myos init <dir>`

Creates the initial templates that the default `docker-compose.yml` expects. These are...

```bash
# vim
vim/binds.vim
vim/helpers.vim
vim/plugins.vim
vim/vimrc
# zsh
zsh/.zlogin
zsh/.zprofile
zsh/.zshenv
zsh/.zshrc
# tmux
tmux/tmux_saves
tmux/install_tmux.sh
tmux/tmux.conf
```

These files are empty (for the most part). You're expected to add your environment specific settings.

### Create
`myos create <name>`

Runs `docker-compose up -d` from the current directory

### Connect
`myos connect`

Connects to a previously created MyOS environment


### Restart

`myos restart <name>`

Restart a previously created MyOS environment

### Remove

`myos remove <name>`

Remove a running MyOS environment

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


## Notes

* CLI currently written in NodeJS as convenience, open to switching to shell or python based CLI
* Very opinionated towards VIM currently, plan to support Emacs and other varities down the road
* Plan to add a CLI command to natively download and try another users setup
* Plan to improve design to allow for multiple MyOS setups on the same machine
* Plan to auto-gen ssh key instead of requiring `authorized_keys`
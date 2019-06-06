FROM phusion/baseimage:master
LABEL Maintainer="Ryland Goldstein <rylandgoldstein@gmail.com>"

# Required for phusion, modifies PID 1
CMD ["/sbin/my_init"]

ENV DEFAULT_USER=ubuntu

# TODO: Fix locale for tmux so hack isn't needed
ENV LC_ALL en_US.UTF-8
# For tmux (it gets confused)
ENV TERM xterm-256color
# Configurable user home
ENV USER_HOME=/home/$DEFAULT_USER
# This stops us from getting spammed about "missing frontend"
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Required for vim repo
RUN apt-get update        --fix-missing
# This vim has clipboard and xclipboard support
RUN add-apt-repository    ppa:jonathonf/vim
RUN apt-get install -y                               \
                          software-properties-common \
                          curl                       \
                          sudo                       \
                          nano                       \                          
                          vim-gtk3


# Now that we have curl let's update again to add yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_12.x | sudo bash -
RUN apt-get update

# Now install everything else
RUN apt-get install -y                               \
                          x11-apps                   \
                          apt-utils                  \
                          zsh                        \
                          curl                       \
                          git                        \
                          wget                       \
                          fontconfig                 \
                          mosh                       \
                          fonts-powerline            \
                          htop                       \
                          build-essential            \
                          python3-pip                \
                          locales                    \
                          nodejs                     \
                          xclip                      \
                          xauth                      \
                          yarn


# TMUX binary always screws me, just build from source
ADD ./templates/tmux/install_tmux.sh ./
RUN ./install_tmux.sh && rm -f ./install_tmux.sh

#########################################################################
# UNIX CONFIG
#########################################################################

# Tmux makes our life difficult, set all of this stuff 
RUN echo "export TERM=xterm-256color" >> /etc/zsh/zprofile
RUN echo "export USER_HOME=${USER_HOME}" >> /etc/zsh/zprofile
RUN echo "export LC_ALL=en_US.UTF-8" >> /etc/zsh/zprofile

# Make sshd directory accessible as non-root user
RUN chmod 0755 /var/run/sshd
# Disable password based authentication with ssh
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# We want X11 features via ssh (for graphical display, clipboard etc)
RUN sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config
# We should be able to send custom env vars
RUN sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/' /etc/ssh/sshd_config

# Enable ssh with phusion (https://github.com/phusion/baseimage-docker#enabling-ssh)
RUN rm -f /etc/service/sshd/down
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# We don't want to run as root even inside our container
RUN adduser --disabled-password --shell /usr/bin/zsh --gecos '' $DEFAULT_USER
RUN adduser $DEFAULT_USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN runuser -l $DEFAULT_USER -c 'mkdir -p $USER_HOME/.ssh'

SHELL ["/usr/bin/zsh", "-c"]

RUN apt-get clean && apt-get autoclean && apt-get autoremove

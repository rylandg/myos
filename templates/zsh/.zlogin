if [[ "$SSH_CONNECTION" != "" && "$MY_SSH_CONNECTION" != "yes" ]]; then
    while true; do
        echo -n "Do you want to attach to a tmux session? [y/n]"
        read yn
        case $yn in
            [Yy]* ) MY_SSH_CONNECTION="yes" tmux new-session -s development -A; break;;
            [Nn]* ) break;;
            * ) echo "Please answer y/n";;
        esac
    done
fi

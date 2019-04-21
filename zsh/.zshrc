function exit {
  echo "Please refrain from using exit, instead use 'ctrl-a'"
}

x-yank() {
    zle copy-region-as-kill
    print -rn -- $CUTBUFFER | xclip -sel clip
    zle exchange-point-and-mark -n -1
}
zle -N x-yank

x-paste() {
    killring=("$CUTBUFFER" "${(@)killring[1,-2]}")
    CUTBUFFER=$(xclip -selection clipboard -o)
    zle yank
}
zle -N x-paste

bindkey -M vicmd "y" x-yank
bindkey -M vicmd "Y" x-yank
bindkey -M vicmd "p" x-paste

# Traditional ZSHRC config goes here
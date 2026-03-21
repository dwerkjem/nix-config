export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(git)

source $ZSH/oh-my-zsh.sh

### set PATH so it includes user's nix bin if it exists
if [ -d "$HOME/.nix-profile/bin" ] ; then
    PATH="$HOME/.nix-profile/bin:$PATH"
fi

### set XDG_DATA_DIR so it includes user's nix share if it exists
if [ -d "$HOME/.nix-profile/share" ] ; then
    XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
fi

export EDITOR="$HOME/.nix-profile/bin/nvim"
export VISUAL="$HOME/.nix-profile/bin/nvim"
export SUDO_EDITOR="$HOME/.nix-profile/bin/nvim"

alias update-system="nix run github:nix-community/home-manager -- switch --flake $HOME/nix-config#$USER"

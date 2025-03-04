# zload
.zshrc
```zsh
PLUGINS=(
    "sindresorhus/pure async.zsh pure.zsh"
    "ohmyzsh/ohmyzsh/lib/completion.zsh"
    "ohmyzsh/ohmyzsh/lib/history.zsh"
    "ohmyzsh/ohmyzsh/lib/key-bindings.zsh"
    "ohmyzsh/ohmyzsh/plugins/sudo/sudo.plugin.zsh"
    "zdharma-continuum/fast-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
    "junegunn/fzf shell completion.zsh key-bindings.zsh"
    "Aloxaf/fzf-tab"
)

ZLOAD_HOME=${HOME}/.zload
ZLOAD_PLUGINS_DIR="${ZLOAD_HOME}/plugins"
if [[ ! -f ${ZLOAD_HOME}/bin/zload.zsh ]]; then
  git clone https://github.com/ttii6/zload.git "${ZLOAD_HOME}/bin"
fi
source ${ZLOAD_HOME}/bin/zload.zsh

zstyle ':prompt:pure:prompt:success' color white
zstyle ':prompt:pure:user' color green
zstyle ':prompt:pure:host' color green
PURE_PROMPT_SYMBOL='▶'

setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

export PATH="${HOME}/.zload/plugins/junegunn/fzf/bin:$PATH"
command -v fzf &> /dev/null || ${ZLOAD_PLUGINS_DIR}/junegunn/fzf/install --bin

#export TERM=xterm-256color
################################################################################
export PATH="$PATH:/usr/sbin"

alias ip="ip -c"
alias l="ls -lF"
alias ll="ls -AlF"
alias ls="ls -F --color=auto"
alias p="sudo ss -tlpn"
alias sys="sudo systemctl"
alias h="htop"
alias j="sudo journalctl"
alias sudo="sudo "
alias vizsh="vi ~/.zshrc"
alias szsh="source ~/.zshrc"

if command -v podman &> /dev/null; then
    alias pd="sudo podman"
    alias pdup="cd ~/disk/install/container && ./setup.sh"
fi

if command -v docker &> /dev/null; then
    alias dk="sudo docker"
    alias dkup="cd ~/disk/install/container && ./setup.sh"
fi

# fedora
if command -v dnf &> /dev/null; then
    alias up="sudo dnf upgrade"
    alias upup="sudo dnf needs-restarting"
    alias d="sudo dnf"
    alias get="sudo dnf install"
    alias clean="sudo dnf clean all"
    alias purge="sudo dnf remove"

    alias update-grub="sudo grub2-mkconfig -o /etc/grub2.cfg"
    alias grubinfo="sudo grubby --info ALL"
fi

# Debian
if command -v apt &> /dev/null; then
    alias up="sudo apt update"
    alias upup="sudo apt upgrade"
    alias a="sudo apt"
    alias get="sudo apt install"
    alias purge="sudo apt --autoremove purge"
fi
```

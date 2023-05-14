# New Machine Setup

## Minimal Items

- (macOS) Install Homebrew
- Install Brave browser
  - Install Bitwarden extension
  - Install Vimium extension
  - Install Video Speed Controller extension
- Install Neovim
- (macOS) Install Rectangle

System76, Ubuntu 20.04

- `sudo apt update && sudo apt-get update`
- `sudo apt full-upgrade -y --fix-missing`
- `sudo apt install tlp`


## Setup Script

```bash
INSTALLS_DIR=$HOME/installs

is_installed() {
  which "$1" || dpkg -s "$1"
}

run_if_not_installed() {
  if ! is_installed "$1"; then
    `$2`
  else
    echo "'$1' is already installed."
  fi
}

# Basic setup
mkdir -p $INSTALLS_DIR
sudo apt update \
  && sudo apt-get update \
  && sudo apt full-upgrade -y --fix-missing \
  && sudo apt install -y \
    curl \
    git  \
    xsel

# tlp
install_tlp() {
  sudo apt install -y tlp
  sudo tlp start
}
run_if_not_installed tlp install_tlp

# rust, cargo
install_rust() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  source $HOME/.cargo/env
}
# depends on basic setup
run_if_not_installed cargo install_rust

# xsel
install_xsel() {
  sudo apt install xsel
}
run_if_not_installed xsel

# fzf
install_fzf() {
  git clone --depth 1 https://github.com/junegunn/fzf.git $INSTALLS_DIR/fzf
  $INSTALLS_DIR/fzf/install
}
# depends on basic setup
run_if_not_installed fzf install_fzf

# navi
install_navi() {
  cargo install navi
  mkdir -p "$(dirname $(navi info config-path))"
  mkdir -p "$(dirname $(navi info cheats-path))"
  navi info config-example > $(navi info config-path)
}
# depends on basic setup, cargo/rust, fzf
run_if_not_installed navi install_navi

# nnn
install_nnn() {
  sudo apt install -y nnn
  curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh
  # add stuff to .bashrc and .profile
}
run_if_not_installed nnn install_nnn

# ripgrep
install_ripgrep() {
  sudo apt install -y ripgrep
}
run_if_not_installed rg install_ripgrep

# vim
install_vim() {
  sudo apt install -y vim
}
run_if_not_installed vim install_vim

# neovim
install_nvim() {
  sudo apt install -y neovim
  echo "export EDITOR=nvim" >> $HOME/.bashrc
}
run_if_not_installed neovim install_nvim

PLATFORM=`uname`
if [[ "$PLATFORM" == "Linux" ]]; then
  # linux stuff
elif [[ "$PLATFORM" == "Darwin" ]]; then
  # mac stuff
fi
```

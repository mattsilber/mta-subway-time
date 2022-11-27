# Sourced mostly from: https://medium.com/@jeffborch/running-the-scenic-elixir-gui-framework-on-windows-10-using-wsl-f9c01fd276f6

set -o pipefail

ELIXIR_VERSION=1.14.2-otp-25
ERLANG_VERSION=25.1.2

sudo apt-get update

sudo apt-get install -y \
  git \
  mesa-utils \
  unzip \
  build-essential \
  autoconf \
  m4 \
  libncurses5-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  libpng-dev \
  libssh-dev \
  unixodbc-dev \
  xsltproc \
  fop \
  make \
  gcc \
  pkgconf \
  libglfw3 \
  libglfw3-dev \
  libglew2.1 \
  libglew-dev \
  libmnl0 \
  libmnl-dev \
  automake \
  squashfs-tools \
  ssh-askpass \
  pkg-config \
  curl \
  libssl-dev \
  bc \
  cmake \
  python \
  libwxgtk3.0-gtk3-dev

# FWup
# Install fwup (https://github.com/fhunleth/fwup)
export FWUP_VERSION="1.9.1"

wget https://github.com/fwup-home/fwup/releases/download/v${FWUP_VERSION}/fwup_${FWUP_VERSION}_amd64.deb

sudo apt-get install -y ./fwup_${FWUP_VERSION}_amd64.deb

rm ./fwup_${FWUP_VERSION}_amd64.deb

# Install asdf to manage elixir version
git clone https://github.com/asdf-vm/asdf.git ~/.asdf

echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc
echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc

# Install Erlang and Elixir
asdf plugin add erlang
asdf install erlang $ERLANG_VERSION
asdf global erlang $ERLANG_VERSION

asdf plugin-add elixir
asdf install elixir $ELIXIR_VERSION
asdf global elixir $ELIXIR_VERSION

mix local.hex --force
mix local.rebar --force

mix archive.install hex nerves_bootstrap --force

mix escript.install hex protobuf --force

asdf reshim elixir

echo "export DISPLAY=localhost:0" >> ~/.bashrc

source ~/.bashrc
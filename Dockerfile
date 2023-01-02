# https://hub.docker.com/_/elixir
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

ARG ELIXIR_VERSION=1.14.2-otp-25
ARG ERLANG_VERSION=25.1.2

SHELL ["/bin/bash", "-c"]

ENV LANG=C.UTF-8

# Install libraries for Nerves development
RUN apt-get update \
  && apt-get install -y \
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
    libwxgtk3.0-gtk3-dev \
    wget \
    sudo

WORKDIR /workspace

ENV GOOGLE_TRANSIT_DATA=/workspace/google_transit

COPY ./scripts /mta-scripts

# Install transit data
RUN /mta-scripts/update_google_transit_data.sh

# Install fwup (https://github.com/fhunleth/fwup)
ENV FWUP_VERSION="1.9.1"

RUN wget https://github.com/fwup-home/fwup/releases/download/v${FWUP_VERSION}/fwup_${FWUP_VERSION}_amd64.deb \
  && apt-get install -y ./fwup_${FWUP_VERSION}_amd64.deb \
  && rm ./fwup_${FWUP_VERSION}_amd64.deb \
  && rm -rf /var/lib/apt/lists/*

# From https://github.com/asdf-community/asdf-ubuntu/blob/master/Dockerfile
RUN adduser --shell /bin/bash --home /asdf --disabled-password asdf
RUN adduser asdf sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> \
/etc/sudoers
ENV PATH="${PATH}:/asdf/.asdf/shims:/asdf/.asdf/bin"

USER asdf

# Install asdf to manage elixir version
RUN git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf \
  && echo ". $HOME/.asdf/asdf.sh" >> $HOME/.bashrc \
  && echo ". $HOME/.asdf/completions/asdf.bash" >> $HOME/.bashrc

# Install Erlang and Elixir
RUN source $HOME/.bashrc \
  && asdf plugin add erlang \
  && asdf install erlang $ERLANG_VERSION \
  && asdf global erlang $ERLANG_VERSION \
  && asdf plugin-add elixir \
  && asdf install elixir $ELIXIR_VERSION \
  && asdf global elixir $ELIXIR_VERSION \
  && asdf reshim

RUN source $HOME/.bashrc \
  && mix local.hex --force \
  && mix local.rebar --force \
  && mix archive.install hex nerves_bootstrap --force

# Generate an SSH-key for host network.
# Totally a bad idea: https://stackoverflow.com/a/27504514/1426565
RUN ssh-keygen -q -t rsa -N '' -f $HOME/.ssh/id_rsa

# Setup Escripts for Protobuf
ENV PATH=$HOME/.mix/escripts:$PATH

RUN mix escript.install hex protobuf --force

CMD ["/bin/bash"]
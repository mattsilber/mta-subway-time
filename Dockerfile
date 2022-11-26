# https://hub.docker.com/_/elixir
FROM elixir:1.14.2

# Install libraries for Nerves development
RUN apt-get update \
  && apt-get install -y \
    build-essential \
    automake \
    autoconf \
    git \
    squashfs-tools \
    ssh-askpass \
    pkg-config \
    curl \
    libssl-dev \
    libncurses5-dev \
    bc \
    m4 \
    unzip \
    cmake \
    python \
    openssh-client \
    libglfw3 \
    libglfw3-dev \
    libglew2.1 \
    libglew-dev \
    sudo \
    libmnl0 \
    libmnl-dev \
    ntp \
    protobuf-compiler

# Install fwup (https://github.com/fhunleth/fwup)
ENV FWUP_VERSION="1.9.1"

RUN wget https://github.com/fwup-home/fwup/releases/download/v${FWUP_VERSION}/fwup_${FWUP_VERSION}_amd64.deb \
  && apt-get install -y ./fwup_${FWUP_VERSION}_amd64.deb \
  && rm ./fwup_${FWUP_VERSION}_amd64.deb \
  && rm -rf /var/lib/apt/lists/*

# Install hex and rebar
RUN mix local.hex --force
RUN mix local.rebar --force

# Install Mix environment for Nerves
RUN mix archive.install hex nerves_bootstrap --force

# Generate an SSH-key for host network.
# Totally a bad idea: https://stackoverflow.com/a/27504514/1426565
RUN ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa

# Setup Escripts for Protobuf
ENV PATH=/root/.mix/escripts:$PATH

RUN mix escript.install hex protobuf --force

CMD ["/bin/bash"]
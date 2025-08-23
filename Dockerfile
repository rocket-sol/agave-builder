ARG AGAVE_VERSION=v2.3.6
ARG AGAVE_SRC_DIR=/home/sol/agave-${AGAVE_VERSION}

FROM ubuntu:jammy AS source

RUN --mount=type=cache,dst=/var/lib/apt apt-get update && apt-get install -y \
  autoconf \
  automake \
  autopoint \
  bash \
  bison \
  build-essential \
  clang \
  cmake \
  flex \
  gcc-multilib \
  gettext \
  git \
  lcov \
  libclang-dev \
  libgmp-dev \
  libprotobuf-dev \
  libssl-dev \
  libudev-dev \
  llvm \
  make \
  pkg-config \
  protobuf-compiler \
  zlib1g-dev \
  ;

RUN useradd --create-home sol

USER sol

WORKDIR /home/sol

ARG AGAVE_VERSION
ARG AGAVE_SRC_DIR
RUN mkdir -p ${AGAVE_SRC_DIR} && curl --fail --location --silent https://github.com/anza-xyz/agave/archive/refs/tags/${AGAVE_VERSION}.tar.gz | tar xvz --strip-components=1 -C ${AGAVE_SRC_DIR}

COPY patches patches
RUN <<EOF
set -e
if [ ! -d "patches/${AGAVE_VERSION}" ] ; then
  exit 0
fi

cat patches/${AGAVE_VERSION}/*.patch | patch --directory agave-${AGAVE_VERSION} --forward --strip 1
EOF

FROM source AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=cache,target=$HOME/.cargo \
  curl --fail --silent --show-error https://sh.rustup.rs | sh -s -- -y --component rustfmt

WORKDIR ${AGAVE_SRC_DIR}
ARG JOBS_NUM=4
RUN --mount=type=cache,target=$HOME/.cargo \
  . $HOME/.cargo/env \
  && ./scripts/cargo-install-all.sh --validator-only .

FROM ubuntu:jammy AS ubuntu
ARG AGAVE_VERSION
ARG AGAVE_SRC_DIR
COPY --from=build ${AGAVE_SRC_DIR}/bin/ /opt/agave/bin/
ENTRYPOINT ["/opt/agave/bin/solana-validator"]

FROM scratch
LABEL org.opencontainers.image.source https://github.com/rocket-sol/agave-builder
ARG AGAVE_VERSION
ARG AGAVE_SRC_DIR
COPY --from=build ${AGAVE_SRC_DIR}/bin/ /

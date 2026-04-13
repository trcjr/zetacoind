FROM debian:stretch-slim AS builder

ARG ZETACOIN_VERSION=v0.14.1.2
ARG ZETACOIN_SOURCE_URL=https://github.com/WikiMin3R/ZetacoinE/archive/refs/tags/v0.14.1.2.tar.gz
ARG MAKE_JOBS=2

ENV DEBIAN_FRONTEND=noninteractive

RUN printf 'deb http://archive.debian.org/debian stretch main\n' > /etc/apt/sources.list \
 && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    binutils \
    build-essential \
    bsdmainutils \
    python3 \
    libssl1.0-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-thread-dev \
    libdb++-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN test -n "${ZETACOIN_SOURCE_URL}" \
 && curl -L "${ZETACOIN_SOURCE_URL}" -o zetacoin-src.tar.gz \
 && tar -xzf zetacoin-src.tar.gz \
 && SRC_DIR="$(tar -tzf zetacoin-src.tar.gz | head -n1 | cut -d/ -f1)" \
 && mv "${SRC_DIR}" zetacoin-src

WORKDIR /tmp/zetacoin-src/src
RUN sed -i \
    -e 's/^ARCH:=.*/ARCH:=$(shell uname -m)/' \
    -e '/BOOST_INCLUDE_PATH=/d' \
    -e '/BOOST_LIB_PATH=/d' \
    -e '/BDB_INCLUDE_PATH=/d' \
    -e '/BDB_LIB_PATH=/d' \
    -e '/OPENSSL_INCLUDE_PATH=/d' \
    -e '/OPENSSL_LIB_PATH=/d' \
    -e 's/-l boost_system-mt/-lboost_system/g' \
    -e 's/-l boost_filesystem-mt/-lboost_filesystem/g' \
    -e 's/-l boost_program_options-mt/-lboost_program_options/g' \
    -e 's/-l boost_thread-mt/-lboost_thread/g' \
    makefile.unix \
 && make -f makefile.unix -j"${MAKE_JOBS}" USE_UPNP=- \
 && strip --strip-unneeded zetacoind


FROM debian:stretch-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN printf 'deb http://archive.debian.org/debian stretch main\n' > /etc/apt/sources.list \
 && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gosu \
    bash \
    curl \
    libssl1.0.2 \
    libdb5.3++ \
    libboost-system1.62.0 \
    libboost-filesystem1.62.0 \
    libboost-thread1.62.0 \
    libboost-program-options1.62.0 \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash zetacoin

WORKDIR /opt/zetacoin

COPY --from=builder --chmod=755 /tmp/zetacoin-src/src/zetacoind /usr/local/bin/zetacoind

COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["zetacoind"]
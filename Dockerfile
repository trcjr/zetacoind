# syntax=docker/dockerfile:1

FROM --platform=$TARGETPLATFORM debian:stretch-slim AS builder

ARG TARGETPLATFORM
ARG TARGETARCH
ARG ZETACOIN_VERSION=v0.14.1.2
ARG ZETACOIN_SOURCE_URL=https://github.com/WikiMin3R/ZetacoinE/archive/refs/tags/v0.14.1.2.tar.gz
ARG MAKE_JOBS=2

ENV DEBIAN_FRONTEND=noninteractive

RUN printf 'deb http://archive.debian.org/debian stretch main\n' > /etc/apt/sources.list \
 && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    file \
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
 && ( \
      curl -fL \
        --retry 8 \
        --retry-delay 5 \
        --connect-timeout 30 \
        --max-time 600 \
        "${ZETACOIN_SOURCE_URL}" \
        -o zetacoin-src.tar.gz \
      && tar -xzf zetacoin-src.tar.gz \
      && SRC_DIR="$(tar -tzf zetacoin-src.tar.gz | head -n1 | cut -d/ -f1)" \
      && mv "${SRC_DIR}" zetacoin-src \
    ) \
 || ( \
      rm -rf /tmp/zetacoin-src /tmp/zetacoin-src.tar.gz \
      && git clone --depth 1 --branch "${ZETACOIN_VERSION}" https://github.com/WikiMin3R/ZetacoinE.git /tmp/zetacoin-src \
    )

WORKDIR /tmp/zetacoin-src/src

RUN case "${TARGETARCH}" in \
      arm64) ZETA_ARCH="aarch64" ;; \
      amd64) ZETA_ARCH="x86_64" ;; \
      arm)   ZETA_ARCH="arm" ;; \
      *)     ZETA_ARCH="${TARGETARCH}" ;; \
    esac \
 && sed -i \
    -e "s/^ARCH:=.*/ARCH:=${ZETA_ARCH}/" \
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
    makefile.unix

RUN find /tmp/zetacoin-src -name '*.o' -delete \
 && find /tmp/zetacoin-src -name '*.a' -delete \
 && find /tmp/zetacoin-src -name '*.so' -delete \
 && rm -f /tmp/zetacoin-src/src/zetacoind \
 && rm -f /tmp/zetacoin-src/src/leveldb/build_config.mk

# Patch old bundled LevelDB for aarch64 if needed
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
      if [ -f /tmp/zetacoin-src/src/leveldb/port/atomic_pointer.h ]; then \
        grep -q '__aarch64__' /tmp/zetacoin-src/src/leveldb/port/atomic_pointer.h || \
        sed -i '/defined(__x86_64__)/s/defined(__x86_64__)/defined(__x86_64__) || defined(__aarch64__)/' \
          /tmp/zetacoin-src/src/leveldb/port/atomic_pointer.h; \
      fi; \
    fi

WORKDIR /tmp/zetacoin-src/src/leveldb

RUN chmod +x build_detect_platform \
 && ./build_detect_platform build_config.mk . \
 && test -f build_config.mk \
 && grep -E 'PLATFORM|ATOMIC|OS_' build_config.mk || true \
 && (make clean || true) \
 && make -j"${MAKE_JOBS}" libleveldb.a libmemenv.a \
 && test -f libleveldb.a \
 && test -f libmemenv.a \
 && file libleveldb.a \
 && file libmemenv.a

WORKDIR /tmp/zetacoin-src/src

RUN (make -f makefile.unix clean || true) \
 && make -f makefile.unix -j"${MAKE_JOBS}" USE_UPNP=- \
 && strip --strip-unneeded zetacoind \
 && file zetacoind


FROM --platform=$TARGETPLATFORM debian:stretch-slim

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
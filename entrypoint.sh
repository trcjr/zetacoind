#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${ZETACOIN_DATA_DIR:-/home/zetacoin/.zetacoin}"
CONF_FILE="${ZETACOIN_CONF:-$DATA_DIR/zetacoin.conf}"

RPC_USER="${COIND_RPC_USER:-zetacoinrpc}"
RPC_PASSWORD="${COIND_RPC_PASSWORD:-changeme}"
P2P_PORT="${COIND_P2P_PORT:-22011}"
RPC_PORT="${COIND_RPC_PORT:-22014}"
RPC_BIND="${COIND_RPC_BIND:-0.0.0.0}"
RPC_ALLOW_IP="${COIND_RPC_ALLOW_IP:-172.16.0.0/12}"
TXINDEX="${COIND_TXINDEX:-1}"
PRUNE="${COIND_PRUNE:-0}"
MAXCONNECTIONS="${COIND_MAXCONNECTIONS:-64}"
EXTRA_ARGS="${COIND_EXTRA_ARGS:-}"

mkdir -p "${DATA_DIR}"
chown -R zetacoin:zetacoin /home/zetacoin

if [[ ! -f "${CONF_FILE}" ]]; then
  cat > "${CONF_FILE}" <<EOF
server=1
daemon=0
listen=1
printtoconsole=1

rpcuser=${RPC_USER}
rpcpassword=${RPC_PASSWORD}
rpcbind=${RPC_BIND}
rpcallowip=${RPC_ALLOW_IP}
rpcport=${RPC_PORT}

port=${P2P_PORT}
txindex=${TXINDEX}
prune=${PRUNE}
maxconnections=${MAXCONNECTIONS}
EOF
  chown zetacoin:zetacoin "${CONF_FILE}"
fi

if [[ "${1:-}" == "zetacoind" ]]; then
  exec gosu zetacoin zetacoind \
    -datadir="${DATA_DIR}" \
    -conf="${CONF_FILE}" \
    ${EXTRA_ARGS}
fi

exec "$@"
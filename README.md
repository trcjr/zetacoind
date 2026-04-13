# zetacoind Docker Image

Containerized Zetacoin daemon (`zetacoind`) with:

- A multi-stage Docker build that compiles `zetacoind` from source
- A runtime entrypoint that auto-generates `zetacoin.conf` on first run
- A `docker-compose.yml` setup for local operation with a persistent data volume
- GitHub Actions publishing to GHCR

## What This Repo Contains

- `Dockerfile`: Builds and packages `zetacoind`
- `docker-entrypoint.sh`: Creates config and starts the daemon as non-root user `zetacoin`
- `docker-compose.yml`: Local service definition and healthcheck
- `.github/workflows/container-publish.yml`: CI build/publish workflow

## Prerequisites

- Docker Engine with Compose support (`docker compose`)
- Optional: GitHub Container Registry access if you want to pull/push `ghcr.io` images

## Quick Start (Docker Compose)

1. Set credentials and ports in `.env`.
2. Start the node:

```bash
docker compose up -d --build
```

3. Check status:

```bash
docker compose ps
docker compose logs -f zetacoind
```

4. Stop:

```bash
docker compose down
```

Blockchain data persists in `./dot-zetacoin`.

## Configuration

The entrypoint writes `zetacoin.conf` if it does not exist at startup.

Primary environment variables:

- `COIND_RPC_USER` (required in practice)
- `COIND_RPC_PASSWORD` (required in practice)
- `COIND_P2P_PORT` (default: `22011`)
- `COIND_RPC_PORT` (compose default: `22012`)
- `COIND_RPC_BIND` (default: `0.0.0.0`)
- `COIND_RPC_ALLOW_IP` (default in compose: `0.0.0.0/0`)
- `COIND_TXINDEX` (default: `1`)
- `COIND_PRUNE` (default: `0`)
- `COIND_MAXCONNECTIONS` (default: `64`)
- `COIND_EXTRA_ARGS` (optional extra CLI args)

Build args (in `docker-compose.yml`):

- `ZETACOIN_VERSION`
- `ZETACOIN_SOURCE_URL`

## Security Notes

- Replace `COIND_RPC_PASSWORD` in `.env` before exposing this service anywhere.
- Restrict `COIND_RPC_ALLOW_IP` and `COIND_RPC_BIND` to trusted networks.
- RPC port mapping is currently enabled in `docker-compose.yml`; remove/comment it if you want RPC to stay private to the compose network.

## Build and Run Without Compose

Build:

```bash
docker build -t zetacoind:local .
```

Run:

```bash
docker run --rm -it \
	-e COIND_RPC_USER=zetacoinrpc \
	-e COIND_RPC_PASSWORD=change_me \
	-p 22011:22011 \
	-p 22012:22012 \
	-v "$PWD/dot-zetacoin:/home/zetacoin/.zetacoin" \
	zetacoind:local
```

## CI/CD Container Publishing

GitHub Actions workflow: `.github/workflows/container-publish.yml`

Behavior:

- `push` to `develop`: builds and pushes `:develop` to GHCR
- `push` tag matching `v*`: builds and pushes version tag and `:latest`
- Manual `workflow_dispatch` with `tag` input: builds/pushes for that tag

Multi-arch publishing is enabled for:

- `linux/amd64`
- `linux/arm64`

Image name format:

```text
ghcr.io/<owner>/<repo>:<tag>
```

## Notes on Base Image

The image currently uses `debian:stretch-slim` for both build and runtime stages to match legacy Zetacoin dependencies.

---

## Donations

If this project helps you, donations are appreciated but never expected.

Running infrastructure (nodes, storage, bandwidth) costs real resources - your support helps keep things online and decentralized.

### Crypto

- BTC: bc1qvhay5salwnyey2cnel9xf8tkejqr79un9ew2g2
- BTC (Lightning): alonemadam426@walletofsatoshi.com
- ETH / EVM (ETH, Base, Arbitrum, etc): 0xf1d140F26f23C82D6Ef58E9F3892e45ad1BC4E4b
- USDC (ERC20 - Ethereum mainnet): 0xf1d140F26f23C82D6Ef58E9F3892e45ad1BC4E4b
- ZET: 99U5yQBcnJ1XS3uKFk3UDY6oXv8yC7Hy5B

Donations do not grant special privileges or influence over the project.

---

## License

MIT License - Copyright (c) 2026 Theodore Robert Campbell Jr

See [LICENSE](LICENSE) for full terms.

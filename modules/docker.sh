#!/usr/bin/env bash
# docker module: Desktop on macOS; Engine on Linux; Desktop+WSL preferred on WSL.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

OS="$(detect_os)"

_install_docker_engine_apt() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "Docker Engine + Compose already available."
    return 0
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    echo "This Linux install path expects apt (Ubuntu/Debian)." >&2
    echo "Install Docker Engine + the Compose plugin for your distro, then re-run doctor." >&2
    exit 1
  fi

  echo "Installing Docker Engine (official apt repository)..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  local codename="${VERSION_CODENAME:-}"
  if [[ -z "$codename" ]]; then
    codename="$(lsb_release -cs 2>/dev/null || true)"
  fi
  if [[ -z "$codename" ]]; then
    echo "Could not detect Ubuntu/Debian codename for the Docker apt repo." >&2
    exit 1
  fi

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  if getent group docker >/dev/null 2>&1; then
    if ! id -nG "$USER" | grep -qw docker; then
      echo "Adding $USER to the docker group (re-login required for passwordless docker)..."
      sudo usermod -aG docker "$USER"
    fi
  fi

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now docker >/dev/null 2>&1 || true
  fi
}

case "$OS" in
  macos)
    ensure_homebrew
    brew_bundle "$SCRIPT_DIR/Brewfile.docker"
    echo ""
    echo "docker module done. Remaining manual step:"
    echo "  - open Docker Desktop once to finish onboarding"
    echo "  - enable Kubernetes under Settings -> Kubernetes if you want a local cluster from Docker Desktop"
    echo "    (or use the 'k8s' module for kubectl/kubectx/k9s instead)"
    ;;

  wsl)
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      echo "Docker CLI already talks to a running daemon (likely Docker Desktop WSL integration)."
      docker compose version >/dev/null 2>&1 || echo "  warning: 'docker compose' not found — enable Compose in Docker Desktop."
      echo ""
      echo "docker module done. Prefer keeping Docker Desktop on Windows with WSL integration enabled"
      echo "  so Mac/Windows feel the same (GUI + shared engine)."
      exit 0
    fi

    echo "No working Docker daemon in this WSL distro yet."
    echo ""
    echo "Recommended (closest to macOS Docker Desktop):"
    echo "  1. Install Docker Desktop for Windows on the host"
    echo "  2. Settings -> Resources -> WSL Integration -> enable this distro"
    echo "  3. Re-open Ubuntu and re-run: ./install.sh docker"
    echo ""
    echo "Fallback: install Docker Engine inside WSL (no Desktop GUI)."
    if [[ "${DOCKER_ENGINE_IN_WSL:-}" == "1" ]]; then
      _install_docker_engine_apt
      echo ""
      echo "docker module done (Engine inside WSL)."
      echo "  - log out of WSL / run 'newgrp docker' so group membership applies"
      echo "  - 'docker info' should work without sudo after that"
    else
      echo "  Re-run with DOCKER_ENGINE_IN_WSL=1 ./install.sh docker to install Engine inside WSL."
      exit 0
    fi
    ;;

  linux)
    _install_docker_engine_apt
    echo ""
    echo "docker module done. Remaining manual steps:"
    echo "  - log out and back in (or run 'newgrp docker') so the docker group applies"
    echo "  - verify with: docker info && docker compose version"
    echo "  - use the 'k8s' module for kubectl/kubectx/k9s"
    ;;

  *)
    echo "Unsupported OS for docker module: $OS" >&2
    exit 1
    ;;
esac

#!/usr/bin/env bash
# Ejecutar en la VM como root antes de la primera promoción S9.
set -euo pipefail
test "$(id -u)" = 0
SWAP=/swapfile-petboutique
if ! swapon --show --noheadings | grep -q .; then
  if [[ ! -e "$SWAP" ]]; then
    fallocate -l 1G "$SWAP"
    chmod 600 "$SWAP"
    mkswap "$SWAP"
  fi
  swapon "$SWAP"
  grep -qF "$SWAP none swap sw 0 0" /etc/fstab || printf '%s\n' "$SWAP none swap sw 0 0" >> /etc/fstab
fi
date -u
free -m
swapon --show

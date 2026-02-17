#!/usr/bin/env bash

# Sometimes you want to run `sudo` with the minimal env args needed to run a binary, or you need the PATH used by nix, this provides that

echo "(run within the repo with the desired nix flake)"

ENV_ARGS=(
"CUSTOM_ENV_VAR=example"
)

NIX_ENV_FILE=$(mktemp)
nix develop --command env > "$NIX_ENV_FILE"
FILTERED_ENV_FILE=$(mktemp)
grep -E '^(PATH|LD_LIBRARY_PATH|NIX_CERT_FILE|NIX_SSL_CERT_FILE|LD_FOR_TARGET)=' "$NIX_ENV_FILE" > "$FILTERED_ENV_FILE"

# Read the filtered env vars into an array
while IFS='=' read -r key value; do
  # Properly quote the values in case they contain spaces
  ENV_ARGS+=("${key}=${value}")
done < <(cat "$FILTERED_ENV_FILE")

echo ${ENV_ARGS[*]}

# if wanting to automate bringing in things to `sudo`
#nix develop --command bash -c "cargo build --release --bin {EXAMPLE} && sudo env ${ENV_ARGS[*]} target/release/{EXAMPLE}"

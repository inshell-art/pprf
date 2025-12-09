#!/usr/bin/env bash

set -euo pipefail

# Quick helper to build, declare, deploy, and sanity-call Pprf on a local devnet.
# Defaults match our current setup; override via env vars if needed.

ACCOUNTS_FILE="${ACCOUNTS_FILE:-/Users/bigu/Projects/path/.accounts/devnet_oz_accounts.json}"
ACCOUNT="${ACCOUNT:-dev_deployer}"
URL="${URL:-http://127.0.0.1:5050}"
PROFILE="${PROFILE:-devnet}"
SALT="${SALT:-}"

artifact="target/dev/glyph_pprf.sierra.json"

echo "==> Building"
scarb build

if [[ ! -f "$artifact" ]]; then
  echo "Build artifact not found: $artifact" >&2
  exit 1
fi

if [[ -n "${CLASS_HASH:-}" ]]; then
  class_hash="$CLASS_HASH"
  echo "==> Using provided CLASS_HASH: $class_hash"
else
  echo "==> Declaring (profile=$PROFILE account=$ACCOUNT url=$URL)"
  declare_out=$(sncast --profile "$PROFILE" --accounts-file "$ACCOUNTS_FILE" --account "$ACCOUNT" declare --contract-name Pprf --url "$URL" 2>&1 || true)
  echo "$declare_out"
  if printf '%s' "$declare_out" | grep -qi 'already declared'; then
    echo "Class already declared; computing class hash locally."
    class_hash=$(starkli class-hash "$artifact")
    echo "Computed class hash: $class_hash"
  else
    class_hash=$(printf '%s\n' "$declare_out" | sed -n 's/^Class Hash: *//p' | head -n1)
    if [[ -z "$class_hash" ]]; then
      echo "Failed to parse class hash from declare output." >&2
      exit 1
    fi
    echo "Parsed class hash: $class_hash"
  fi
fi

echo "==> Deploying"
deploy_args=(--accounts-file "$ACCOUNTS_FILE" --account "$ACCOUNT" deploy --class-hash "$class_hash" --url "$URL")
if [[ -n "$SALT" ]]; then
  deploy_args+=(--salt "$SALT")
fi
deploy_out=$(sncast "${deploy_args[@]}")
echo "$deploy_out"
contract_addr=$(printf '%s\n' "$deploy_out" | sed -n 's/^Contract Address: *//p' | head -n1)
if [[ -z "$contract_addr" ]]; then
  echo "Failed to parse contract address from deploy output." >&2
  exit 1
fi
echo "Parsed contract address: $contract_addr"

echo "==> Sanity check: render(1,2,3)"
sncast call --url "$URL" --contract-address "$contract_addr" --function render --calldata 3 1 2 3

echo "==> Sanity check: metadata()"
sncast call --url "$URL" --contract-address "$contract_addr" --function metadata

echo "Done. Class hash: $class_hash"
echo "       Address:   $contract_addr"

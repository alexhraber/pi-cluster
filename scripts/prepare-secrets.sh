#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

repo_root=$(git rev-parse --show-toplevel)
key_file=${AGE_KEY_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/pi-cluster/age.key}
output_file="$repo_root/secrets/cluster.yaml"
sops_file="$repo_root/secrets/.sops.yaml"

command -v age-keygen >/dev/null 2>&1 || die 'age-keygen is required'
command -v sops >/dev/null 2>&1 || die 'sops is required; enter the Nix development shell'
[[ -e /dev/tty ]] || die 'an interactive terminal is required to read the token without shell arguments'

key_file=$(realpath -m "$key_file")
case "$key_file" in
  "$repo_root"/*) die 'AGE_KEY_FILE must be outside the repository' ;;
esac

mkdir -p "$(dirname "$key_file")"
umask 077
if [[ ! -e "$key_file" ]]; then
  age-keygen -o "$key_file" >/dev/null 2>&1
fi
chmod 600 "$key_file"
recipient=$(age-keygen -y "$key_file")
[[ "$recipient" == age1* ]] || die 'could not derive an age recipient from AGE_KEY_FILE'

if [[ ! -e "$sops_file" ]]; then
  sed "s|<REPLACE_WITH_OPERATOR_AGE_RECIPIENT>|$recipient|" \
    "$repo_root/secrets/.sops.yaml.example" > "$sops_file"
  chmod 600 "$sops_file"
fi

if [[ -e "$output_file" ]]; then
  die 'secrets/cluster.yaml already exists; remove it only through an intentional rotation procedure'
fi

plain_file=$(mktemp "${TMPDIR:-/tmp}/pi-cluster-secrets.XXXXXX")
cleanup() {
  if command -v shred >/dev/null 2>&1; then
    shred --remove --zero "$plain_file" 2>/dev/null || rm -f "$plain_file"
  else
    rm -f "$plain_file"
  fi
}
trap cleanup EXIT INT TERM
chmod 600 "$plain_file"

printf 'Enter the K3s server token. It will not be accepted as a command-line argument.\n' > /dev/tty
IFS= read -r -s token < /dev/tty
printf '\nConfirm the K3s server token:\n' > /dev/tty
IFS= read -r -s confirmation < /dev/tty
printf '\n' > /dev/tty
[[ -n "$token" ]] || die 'token must not be empty'
[[ "$token" == "$confirmation" ]] || die 'token confirmation did not match'

printf 'k3s:\n  server-token: ' > "$plain_file"
printf '%s\n' "$token" >> "$plain_file"
SOPS_AGE_KEY_FILE="$key_file" sops --encrypt --input-type yaml --output-type yaml \
  --age "$recipient" "$plain_file" > "$output_file"
chmod 600 "$output_file"

SOPS_AGE_KEY_FILE="$key_file" sops --decrypt "$output_file" >/dev/null \
  || die 'encrypted payload did not decrypt with the generated recovery key'
grep -q 'ENC\[' "$output_file" \
  || die 'output does not look like an encrypted sops payload'

printf 'Encrypted payload created: %s\n' "$output_file"
printf 'Age key retained outside the repository: %s\n' "$key_file"
printf 'Next: record a protected recovery copy of the age key, then review the staged encrypted diff.\n'

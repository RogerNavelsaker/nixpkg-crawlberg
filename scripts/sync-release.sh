#!/usr/bin/env bash
# Sync flake.nix version + per-target hashes from the latest xberg-io/crawlberg release.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
tag=$(gh api repos/xberg-io/crawlberg/releases/latest --jq .tag_name)
version=${tag#v}
current=$(grep -oE '^\s*version = "[^"]+"' flake.nix | head -n1 | sed -E 's/.*"([^"]+)"/\1/')
[ "$current" != "$version" ] || { echo "already at $version"; exit 0; }
for name in $(grep -oE 'name = "[a-z0-9_-]+-[a-z0-9_-]+-[a-z0-9_-]+";' flake.nix | sed -E 's/name = "([^"]+)";/\1/'); do
  hash=$(nix store prefetch-file --json "https://github.com/xberg-io/crawlberg/releases/download/$tag/crawlberg-cli-$name.tar.gz" | jq -r .hash)
  NAME=$name HASH=$hash perl -0pi -e 's/(name = "\Q$ENV{NAME}\E";\s*hash = ")[^"]+(")/$1$ENV{HASH}$2/' flake.nix
done
sed -i "s/$current/$version/g" flake.nix
echo "synced crawlberg $version"

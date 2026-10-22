# nixpkg-crawlberg

Nix flake packaging for the upstream [Crawlberg](https://github.com/xberg-io/crawlberg) CLI.

The package pins upstream release **1.12.0** and uses its official per-platform release archives and SHA-256 checksums. It is available as `crawlberg` and `packages.default` on x86_64/aarch64 Linux and aarch64 macOS.

```sh
nix build .#crawlberg
nix run .# -- --help
nix flake check
```

This packages the upstream CLI binary; it does not compile or patch upstream source.

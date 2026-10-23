# nixpkg-crawlberg

Nix flake packaging for the upstream [Crawlberg](https://github.com/xberg-io/crawlberg) CLI.

The package pins upstream release **1.12.0** and uses its official per-platform release archives and SHA-256 checksums. It is available as `crawlberg` and `packages.default` on x86_64/aarch64 Linux and aarch64 macOS.

On Linux, the CLI runs in a Nixpkgs FHS environment that provides the `/bin/sh` and `/bin/sleep` paths required by Crawlberg's Unix browser guardian. The wrapper uses bubblewrap, so the host must permit its mount namespace setup. It does not bundle Chromium; Crawlberg still uses a browser supplied by the runtime environment. On macOS, the upstream binary runs directly.

```sh
nix build .#crawlberg
nix run .# -- --help
nix flake check
```

The package uses the upstream CLI binary and does not compile or patch upstream source.

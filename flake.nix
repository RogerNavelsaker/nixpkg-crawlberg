{
  description = "Nix package for the Crawlberg web crawler CLI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      targets = {
        "x86_64-linux" = {
          name = "x86_64-unknown-linux-gnu";
          hash = "sha256-Ylezi50BJfM5U6A26e9K5ZrFUdhRtlwhYtBuNRsDUac=";
        };
        "aarch64-linux" = {
          name = "aarch64-unknown-linux-gnu";
          hash = "sha256-6maR1MtN4+s6BQbPtKYdwcjHwN8IeIg5bA/+m9JkNxM=";
        };
        "aarch64-darwin" = {
          name = "aarch64-apple-darwin";
          hash = "sha256-50mKRFG9Hdh6xPD7SLDZbRCydUKYkvof+Ok0iiXJ2ZY=";
        };
      };
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs { inherit system; }) system);
    in {
      packages = forAllSystems (pkgs: system:
        let
          target = targets.${system};
          crawlbergBin = pkgs.stdenv.mkDerivation {
            pname = "crawlberg";
            version = "1.12.0";

            src = pkgs.fetchurl {
              url = "https://github.com/xberg-io/crawlberg/releases/download/v1.12.0/crawlberg-cli-${target.name}.tar.gz";
              inherit (target) hash;
            };

            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.autoPatchelfHook
            ];
            buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.stdenv.cc.cc.lib
            ];

            dontBuild = true;

            installPhase = ''
              runHook preInstall
              install -Dm755 crawlberg "$out/bin/crawlberg"
              install -Dm644 LICENSE "$out/share/licenses/crawlberg/LICENSE"
              runHook postInstall
            '';

            meta = {
              description = "High-performance web crawling and scraping CLI";
              homepage = "https://github.com/xberg-io/crawlberg";
              license = pkgs.lib.licenses.mit;
              mainProgram = "crawlberg";
              platforms = systems;
            };
          };
          crawlberg = if pkgs.stdenv.hostPlatform.isLinux then
            pkgs.buildFHSEnv {
              pname = "crawlberg";
              version = "1.12.0";
              executableName = "crawlberg";
              targetPkgs = _: [ crawlbergBin ];
              runScript = "${crawlbergBin}/bin/crawlberg";
              meta = crawlbergBin.meta;
            }
          else crawlbergBin;
        in {
          default = crawlberg;
          crawlberg = crawlberg;
        });

      checks = forAllSystems (pkgs: system:
        let
          crawlberg = self.packages.${system}.crawlberg;
        in {
          cli-help = pkgs.runCommand "crawlberg-cli-help" {
            nativeBuildInputs = [ crawlberg ];
          } ''
            crawlberg --help > "$out"
            grep -q "crawlberg" "$out"
          '';
        } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          browser-guardian-runtime = pkgs.runCommand "crawlberg-browser-guardian-runtime" { } ''
            test -x ${crawlberg.fhsenv}/usr/bin/sh
            test -x ${crawlberg.fhsenv}/usr/bin/sleep
            touch "$out"
          '';
        });
    };
}

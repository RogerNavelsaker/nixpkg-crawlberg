{
  description = "Nix package for the Crawlberg web crawler CLI";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://rogernavelsaker.cachix.org"
      "https://nacosolutions.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "rogernavelsaker.cachix.org-1:n1DtzMNhA9Rz4Kg3xlXOi/KceULu8VrMbs9WXyMFQNQ="
      "nacosolutions.cachix.org-1:JzCiW2CLcuLXtwOVAg3SlSK/kpqWbfSFEVenyKVUlug="
    ];
  };

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
          hash = "sha256-YDCaWO2y30zNkT6PXLlRFSE22OJMSrds6vkUoYqRG9o=";
        };
        "aarch64-linux" = {
          name = "aarch64-unknown-linux-gnu";
          hash = "sha256-3mXd6gGa5LWRYd+g4qoi9kSbYsfmCz4H/P2pSDVteyM=";
        };
        "aarch64-darwin" = {
          name = "aarch64-apple-darwin";
          hash = "sha256-FMTDib6VV4F59WKxd9KFcFGiMOazn8n5BoA0JopDeN8=";
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
            version = "1.13.6";

            src = pkgs.fetchurl {
              url = "https://github.com/xberg-io/crawlberg/releases/download/v1.13.6/crawlberg-cli-${target.name}.tar.gz";
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
              version = "1.13.6";
              executableName = "crawlberg";
              targetPkgs = _: [ crawlbergBin ];
              runScript = "${crawlbergBin}/bin/crawlberg";
              meta = crawlbergBin.meta;
            }
          else crawlbergBin;
        in {
          default = crawlberg;
          crawlberg = crawlberg;
          crawlberg-bin = crawlbergBin;
        });

      checks = forAllSystems (pkgs: system:
        let
          crawlberg = self.packages.${system}.crawlberg;
          crawlbergBin = self.packages.${system}.crawlberg-bin;
        in {
          cli-help = pkgs.runCommand "crawlberg-cli-help" {
            nativeBuildInputs = [ crawlbergBin ];
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

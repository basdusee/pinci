{
  description = "Flake for building embedded Rpi Pico image";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = { 
      url = "github:oxalica/rust-overlay"; 
      inputs.nixpkgs    .follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            rust-overlay.overlays.default (final: prev:
              let
                # If you have a rust-toolchain file for rustup, set `choice =
                # rust-tcfile` further down to get the customized toolchain
                # derivation.
                rust-tcfile  = final.rust-bin.fromRustupToolchainFile ./rust-toolchain;
                rust-latest  = final.rust-bin.stable .latest      ;
                rust-beta    = final.rust-bin.beta   .latest      ;
                rust-nightly = final.rust-bin.nightly."2022-08-13";
                rust-stable  = final.rust-bin.stable ."1.63.0"    ; # nix flake lock --update-input rust-overlay
                rust-analyzer-preview-on = date:
                  final.rust-bin.nightly.${date}.default.override {
                    extensions = [ "rust-analyzer-preview" ];
                  };
              in
                rec {
                  choice = rust-latest;

                  rust-tools = choice.default.override {
                    # extensions = [];
                    targets = [ "thumbv6m-none-eabi" ];
                  };
                  rust-analyzer-preview = rust-analyzer-preview-on "2022-08-13";
                  rust-src = rust-stable.rust-src;
                })
          ];
        };

      in {
        # For `nix build` & `nix run`:
        defaultPackage = pkgs.rustPlatform.buildPackage {
          src = ./.;
        };

        # For `nix develop` 
        devShell = pkgs.mkShell {

          buildInputs = with pkgs; [
            rust-tools
            rustfmt
            clippy
            rust-analyzer
            elf2uf2-rs
            flip-link
          ];
          
          # Certain Rust tools won't work without this
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      };
    }
  );
}

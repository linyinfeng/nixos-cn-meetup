{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      perSystem =
        {
          self',
          pkgs,
          lib,
          ...
        }:
        {
          packages.slides = pkgs.callPackage ./slides {};
          checks = self'.packages;
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              prettier.enable = true;
              typstyle = true;
            };
          };
          devShells.default = pkgs.mkShell {
            env.TYPST_FONT_PATHS = lib.concatStringsSep ":" (with pkgs; [
               "${source-sans}/share/fonts/truetype"
               "${source-han-sans}/share/fonts/truetype"
               "${sarasa-gothic}/share/fonts/truetype" ]);
            nativeBuildInputs = with pkgs; [
              typst
              fd
            ];
          };
        };
    };
}

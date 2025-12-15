{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = with pkgs; [
    typst
    typstyle
    treefmt
    nixfmt
  ];
}

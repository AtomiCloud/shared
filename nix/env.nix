{ pkgs, packages }:
with packages;
{
  system = [
    atomiutils
  ];

  dev = [
    pls
    git
    sg
    typescript-language-server
  ];

  main = [
    infisical
    bun
    cyanprint
  ];

  lint = [
    # core
    treefmt
    shellcheck
    sg
  ];

  releaser = [
    sg
  ];
}

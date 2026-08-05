{ pkgs }:

let
  beamPackages = pkgs.beamMinimal29Packages.extend (_: prev: { elixir = prev.elixir_1_20; });
in
pkgs.mkShell {
  packages = [
    beamPackages.elixir
    (beamPackages.elixir-ls.override { elixir = beamPackages.elixir; })
    pkgs.inotify-tools
    pkgs.nixfmt
  ];

  shellHook = ''
    export ERL_AFLAGS="-kernel shell_history enabled shell_history_file_bytes 1024000"
  '';
}

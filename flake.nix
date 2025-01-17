{
  inputs = {
    lean = {
      url = "github:leanprover/lean4";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    lean-std = {
      url = "github:Anderssorby/std4";
      inputs.lean.follows = "lean";
    };
  };

  outputs = { self, lean, flake-utils, nixpkgs, lean-std }:
    let
      supportedSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      inherit (flake-utils) lib;
    in
    lib.eachSystem supportedSystems (system:
      let
        leanPkgs = lean.packages.${system};
        pkgs = nixpkgs.legacyPackages.${system};
        name = "YatimaStdLib";  # must match the name of the top-level .lean file
        project = leanPkgs.buildLeanPackage {
          inherit name;
          deps = [ lean-std.project.${system} ];
          # Where the lean files are located
          src = ./.;
        };
      in
      {
        inherit project;
        packages = project // {
          ${name} = project.sharedLib;
        };

        defaultPackage = self.packages.${system}.${name};
        devShells = {
          lean-dev = pkgs.mkShell {
            buildInputs = with pkgs; [
              leanPkgs.lean-dev
            ];
            LEAN_PATH = "./src:./test";
            LEAN_SRC_PATH = "./src:./test";
          };
          elan = pkgs.mkShell {
            buildInputs = with pkgs; [
              elan
            ];
          };
          default = self.devShells.${system}.elan;
        };
      });
}

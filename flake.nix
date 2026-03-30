{
  description = "Hardware-Accelerated llama.cpp Perk Card";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      # We create a version of nixpkgs that allows unfree (for CUDA)
      # and explicitly uses CUDA support
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };
    in {
      packages.${system}.default = (pkgs.llama-cpp.override {
        # This tells Nix to use the CUDA 12 toolkit for the build
        cudaPackages = pkgs.cudaPackages_12;
      }).overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DCMAKE_CUDA_ARCHITECTURES=120"
        ];
      });

      # Allow running it directly
      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/llama-cli";
      };
    };
}

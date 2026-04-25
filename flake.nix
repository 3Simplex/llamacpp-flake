{
  description = "Hardware-Accelerated llama.cpp (Upstream)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    llama-cpp.url = "github:ggml-org/llama.cpp";
  };

  outputs = { self, nixpkgs, llama-cpp }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };

      # We override the upstream cuda package to explicitly use the auto-matched CUDA toolchain.
      llama-cuda-auto = llama-cpp.packages.${system}.cuda.override {
        cudaPackages = pkgs.cudaPackages;
      };
    in {
      packages.${system}.default = llama-cuda-auto.overrideAttrs (old: {
        cmakeFlags =
          (builtins.filter
            (flag:
              builtins.typeOf flag == "string"
              && builtins.match ".*CMAKE_CUDA_ARCHITECTURES.*" flag == null
            )
            (old.cmakeFlags or [])
          )
          ++ [
            "-DCMAKE_CUDA_ARCHITECTURES=120"
          ];
      });

      devShells.${system}.default = pkgs.mkShell {
        name = "llamacpp-dev";
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      };
    };
}

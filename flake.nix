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
      
      # We override the upstream cuda package to explicitly use the CUDA 12.8 toolchain.
      llama-cuda-12_8 = llama-cpp.packages.${system}.cuda.override {
        cudaPackages = pkgs.cudaPackages_12_8;
      };
    in {
      packages.${system}.default = llama-cuda-12_8.overrideAttrs (old: {
        cmakeFlags = (builtins.filter (flag: builtins.typeOf flag == "string" && builtins.match ".*CMAKE_CUDA_ARCHITECTURES.*" flag == null) (old.cmakeFlags or [])) ++[
          "-DCMAKE_CUDA_ARCHITECTURES=120"
        ];
      });
    };
}

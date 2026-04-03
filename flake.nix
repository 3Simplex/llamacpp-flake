{
  description = "Hardware-Accelerated llama.cpp (Upstream)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    llama-cpp.url = "github:ggml-org/llama.cpp";
  };

  outputs = { self, nixpkgs, llama-cpp }:
    let
      system = "x86_64-linux";
    in {
      packages.${system}.default = llama-cpp.packages.${system}.cuda;
    };
}

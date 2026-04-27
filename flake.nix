{
  description = "Hardware-Accelerated llama.cpp (Upstream)";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    llama-cpp = {
      url = "github:ggml-org/llama.cpp";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, llama-cpp }:
    let
      system = "x86_64-linux";
      # ── Update this one line when your CUDA version changes ──
      cudaVersion = "cudaPackages_13_2";
      # ─────────────────────────────────────────────────────────
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
      cudaPkgs = pkgs.${cudaVersion};
    in {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "llama-cpp-cuda";
        src = llama-cpp;
        nativeBuildInputs = [
          pkgs.cmake
          pkgs.ninja
          cudaPkgs.cuda_nvcc
        ];
        buildInputs = [
          cudaPkgs.cudatoolkit
          cudaPkgs.cuda_cudart
        ];
        cmakeFlags = [
          "-DGGML_CUDA=ON"
          "-DCMAKE_CUDA_ARCHITECTURES=120"
          "-DLLAMA_BUILD_TESTS=OFF"
        ];
        NIXPKGS_ALLOW_UNFREE = "1";
        installPhase = ''
          cmake --install . --prefix $out
        '';
      };
      devShells.${system}.default = pkgs.mkShell {
        name = "llamacpp-dev";
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      };
    };
}

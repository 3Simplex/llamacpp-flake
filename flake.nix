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
      # ── Update this to match your GPU (120=Blackwell, 89=Ada/40xx, 86=Ampere/30xx) ──
      cudaArch = "120";
      # ─────────────────────────────────────────────────────────
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true;
      };
      cudaPkgs = pkgs.${cudaVersion};
    in {

# Use pkgs.stdenv to get the newer GCC version you had in your devShell
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "llama-cpp-cuda";
        src = llama-cpp;

        nativeBuildInputs =[
          pkgs.cmake
          pkgs.ninja
          cudaPkgs.cuda_nvcc
        ];

        buildInputs =[
          cudaPkgs.cudatoolkit
          cudaPkgs.cuda_cudart
          cudaPkgs.libcublas
        ];

        # 1. FORCE -O3 OPTIMIZATION & NATIVE INSTRUCTIONS
        # Overrides Nix's default -O2 to match raw CMake Release speeds
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
        NIX_ENFORCE_NO_NATIVE = 0;

        # 2. DISABLE NIX SECURITY HARDENING
        hardeningDisable = [ "all" ];

        cmakeFlags =[
          "-DGGML_CUDA=ON"
          "-DCMAKE_CUDA_ARCHITECTURES=${cudaArch}"
          "-DLLAMA_BUILD_TESTS=OFF"
          "-DGGML_NATIVE=ON"
          "-DGGML_LTO=ON" # Link-Time Optimization for faster CPU sampling

          # Force CMake to strictly respect -O3
          "-DCMAKE_C_FLAGS=-O3"
          "-DCMAKE_CXX_FLAGS=-O3"
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "llamacpp-dev";
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
          cudaPkgs.cudatoolkit
          cudaPkgs.cuda_cudart
          cudaPkgs.libcublas
        ] + ":/run/opengl-driver/lib";
      };
    };
}

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
      packages.${system}.default = cudaPkgs.backendStdenv.mkDerivation {
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

        # 1. PREVENT NIX FROM STRIPPING CPU OPTIMIZATIONS
        # This is the magic flag that allows AVX/AVX2/FMA optimizations to pass through
        NIX_ENFORCE_NO_NATIVE = 0;

        cmakeFlags =[
          "-DGGML_CUDA=ON"
          "-DCMAKE_CUDA_ARCHITECTURES=${cudaArch}"
          "-DLLAMA_BUILD_TESTS=OFF"
          "-DGGML_NATIVE=ON" # Explicitly enable native CPU optimizations

          # Optional Pro-tip: Enable FlashAttention if your GPU is Ampere (86) or newer.
          # Greatly speeds up prompt processing (PP).
          "-DGGML_CUDA_FA=ON"
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

# Building BulletSim

BulletSim consists of three components:

1. **Bullet Physics Engine** (3.x) – Statically compiled physics library
2. **BulletSim C++ Glue Code** – Integration layer between OpenSim C# and Bullet
3. **Build Artifacts** – Versioned binaries (DLL, SO, dylib) for distribution

This document covers the build process for **Windows, Linux, and macOS**.

---

## System Requirements

### Windows (x64 only)

**Required:**

- **CMake** 3.20+ (`cmake --version` to verify)
- **Git** 2.30+ (`git --version` to verify)
- **Visual Studio 2022** with C++ workload (MSBuild + MSVC compiler)
  - Installed via Visual Studio Installer
  - MSBuild located via `vswhere.exe` (automatic in build script)

**System Architecture:**

- Only 64-bit (`x64`) builds are supported
- Windows 10/11 (Server 2016+ also supported)

**Verification:**

```batch
cmake --version
git --version
where vswhere.exe
```

### Linux (x86_64 / aarch64)

**Required:**

- **CMake** 3.20+ (`cmake --version`)
- **Git** 2.30+ (`git --version`)
- **C++ Compiler** (one of):
  - GCC 10+ with C++17 support
  - Clang 10+ with C++17 support
- **GNU Make** 4.0+

**Installation (examples):**

Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y cmake git build-essential
```

RHEL/CentOS/Fedora:

```bash
sudo dnf install cmake git gcc-c++ make
```

Alpine:

```bash
apk add cmake git g++ make
```

**Verification:**

```bash
cmake --version
git --version
gcc --version  # or 'clang --version'
make --version
```

### macOS (arm64 / x86_64 universal)

**Required:**

- **Xcode Command Line Tools** with C++ support

  ```bash
  xcode-select --install
  ```

- **CMake** 3.20+ (via Homebrew or downloaded binary)

  ```bash
  brew install cmake  # if using Homebrew
  ```

- **Git** (included with Xcode)

**System Architecture:**

- Native M-series (arm64): Apple Silicon Macs (M1/M2/M3...)
- Intel (x86_64): Older Intel-based Macs
- **Universal binary (both architectures)** is built automatically on M-series Macs

**Verification:**

```bash
xcode-select --print-path
cmake --version
clang --version
sw_vers  # Check OS version
```

---

## Quick Start

### Windows

```batch
rem Optional: Clean old artifacts
01buildBulletClear.bat

rem Step 1: Build Bullet 3.x
02buildBulletCMake.bat

rem Step 2: Build BulletSim
03buildBulletSim.bat
```

**Output:**

- Build logs: `logs/buildBulletCMake.log`, `logs/buildBulletSim.log`
- Libraries: `lib/*.lib`
- Headers: `include/`
- BulletSim DLL: `BulletSim\x64\Release\BulletSim.dll`

### Linux / macOS

```bash
# Optional: Clean old artifacts
./l01buildBulletClear.sh

# Step 1: Build Bullet 3.x
./l02buildBulletCMake.sh

# Step 2: Build BulletSim
./l03buildBulletSim.sh
```

**Output:**

- Libraries: `lib/*.a`
- Headers: `include/`
- BulletSim SO/dylib: `libBulletSim-3.25-20260324-x86_64.so` (Linux) or `libBulletSim-3.25-20260324-universal.dylib` (macOS)

---

## Build Configuration

### Environment Variables

All build scripts respect the following environment variables:

#### Common Variables

| Variable | Default | Purpose | Required |
| --- | --- | --- | --- |
| `BULLETDIR` | `bullet3` | Path to Bullet source directory | No |
| `BULLET_REQUIRED_VERSION` | *(unset)* | Pin exact Bullet version (e.g., `3.27`) | No |

#### Windows-Specific Variables

| Variable | Default | Purpose | Required |
| --- | --- | --- | --- |
| `BULLETMACH` | `x64` | Target architecture (`x64` only) | No |
| `BULLETCMAKE_GENERATOR` | `Visual Studio 17 2022` | CMake generator for MSBuild | No |
| `BULLETCMAKE_ARGS` | *(empty)* | Additional CMake arguments | No |

#### Linux/macOS Variables

| Variable | Default | Purpose | Required |
| --- | --- | --- | --- |
| `UNAME` | `$(uname)` | OS name override | No |
| `MACH` | `$(uname -m)` | Architecture override | No |
| `CC` | `c++` | C++ compiler executable | No |
| `LD` | `c++` | Linker executable | No |

### Examples

### Windows: Build with custom Bullet 3.27

```batch
set BULLET_REQUIRED_VERSION=3.27
set BULLETDIR=bullet3
02buildBulletCMake.bat
03buildBulletSim.bat
```

### Linux: Build with specific CMake flags

```bash
export BULLETCMAKE_ARGS="-DCMAKE_CXX_FLAGS=-march=native"
BULLETDIR=bullet3 ./l02buildBulletCMake.sh
./l03buildBulletSim.sh
```

### macOS: Force specific compiler

```bash
export CC=clang
export LD=clang++
./l02buildBulletCMake.sh
./l03buildBulletSim.sh
```

---

## CMake Configuration Details

### Windows CMake Invocation

```batch
cmake -G "Visual Studio 17 2022" -A x64 ^\n    -DBUILD_BULLET3=ON ^\n    -DBUILD_EXTRAS=ON ^\n    -DBUILD_SHARED_LIBS=OFF ^\n    ..\ncmake --build . --config Release\n```
**Key Settings:**

    -DBUILD_BULLET3=ON \
    -DBUILD_EXTRAS=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_CXX_FLAGS="-fPIC" \
    -DCMAKE_BUILD_TYPE=Release

cmake --build . --parallel 4
```

**Key Settings:**

- Generator: Unix Makefiles
- Position-independent code: `-fPIC` (for SO)
- Build type: Release (optimized)
- Parallel jobs: 4 (adjust for your system)

### macOS CMake Invocation

```bash
cmake .. -G "Unix Makefiles" \
    -DBUILD_BULLET3=ON \
    -DBUILD_EXTRAS=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DCMAKE_CXX_FLAGS="-arch x86_64 -arch arm64" \
    -DCMAKE_C_FLAGS="-arch x86_64 -arch arm64 -fPIC -O2" \
    -DCMAKE_BUILD_TYPE=Release

cmake --build . --parallel 4
```

**Key Settings:**

- Generator: Unix Makefiles
- Universal binary: Both `x86_64` and `arm64` architectures
- Architecture flags: Explicit `-arch` directives
- Final output: Single `libBulletSim...univers.dylib` file

---

## Build Artifacts & Output

### Windows Artifacts

| Artifact | Location | Purpose |
| --- | --- | --- |
| `.lib` files | `lib/` | Static Bullet libraries (linked during BulletSim build) |
| Header files | `include/` | Bullet C++ headers |
| `BulletSim.dll` | `BulletSim\x64\Release\` | Dynamically loadable BulletSim module (for OpenSim) |
| `BulletSim.lib` | `BulletSim\x64\Release\` | Import library for linking |
| `BulletSim.pdb` | `BulletSim\x64\Release\` | Debug symbols (optional) |
| Build log | `logs/buildBulletCMake.log` | CMake build output |

### Linux Artifacts

| Artifact | Location | Purpose |
| --- | --- | --- |
| `.a` files | `lib/` | Static Bullet libraries (linked during BulletSim build) |
| Header files | `include/` | Bullet C++ headers |
| `libBulletSim-3.25-20260324-x86_64.so` | root | Loadable BulletSim module for Linux |

**Example filename breakdown:**

- `libBulletSim` – Library name
- `3.25` – Bullet version used
- `20260324` – Build date (YYYYMMDD)
- `x86_64` or `aarch64` – Architecture

### macOS Artifacts

| Artifact | Location | Purpose |
| --- | --- | --- |
| `.a` files | `lib/` | Static Bullet libraries (linked during BulletSim build) |
| Header files | `include/` | Bullet C++ headers |
| `libBulletSim-3.25-20260324-universal.dylib` | root | Universal (arm64+x86_64) macOS module |

**Example filename breakdown:**

- `libBulletSim` – Library name
- `3.25` – Bullet version used
- `20260324` – Build date (YYYYMMDD)
- `universal` – Both arm64 and x86_64 architectures included

---

## Troubleshooting

### Windows: CMake not found

**Error:** `ERROR: cmake was not found in PATH`

**Solution:**

1. Download CMake from <https://cmake.org/download/>
2. Install to default location (adds to PATH)
3. Restart terminal or add CMake to PATH manually:

   ```batch
   set PATH=C:\Program Files\CMake\bin;%PATH%
   ```

### Windows: Visual Studio not found

**Error:** `ERROR: MSBuild.exe nicht gefunden`

**Solution:**

1. Install Visual Studio 2022 with C++ workload
2. Verify `vswhere.exe` can locate it:

   ```batch
   "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest
   ```

3. If empty, reinstall Visual Studio C++ component

### Linux: Build fails with compiler error

**Error:** `error: no matching function for call to...`

**Solutions:**

1. Ensure C++17 support:

   ```bash
   g++ --version  # Should be 10+
   ```

2. Force specific compiler:

   ```bash
   export CC=gcc CXX=g++
   ./l02buildBulletCMake.sh
   ```

3. Check build log:

   ```bash
   tail -100 logs/buildBulletCMake.log
   ```

### macOS: ARM64 architecture not built

**Error:** `libBulletSim...universal.dylib` contains only x86_64

**Solutions:**

1. Verify CMake supports arm64:

   ```bash
   cmake --version  # Should be 3.20+
   ```

2. Force universal build flags:

   ```bash
   export BULLETCMAKE_ARGS="-DCMAKE_OSX_ARCHITECTURES=x86_64;arm64"
   ./l02buildBulletCMake.sh
   ```

3. Check actual architectures in dylib:

   ```bash
   lipo -info libBulletSim*.dylib
   ```

### macOS: glibc compatibility issue

**Note:** The `l03buildBulletSim.sh` script automatically wraps `memcpy` on 64-bit Linux to avoid glibc 2.14+ dependencies (see line ~70). This is not needed on macOS.

---

## Deployment

### Copy to OpenSimulator Installation

After successful build, copy the BulletSim binary to your OpenSim runtime:

**Linux:**

```bash
cp libBulletSim-*.so /path/to/opensim/bin/lib64/
```

**macOS:**

```bash
cp libBulletSim-*.dylib /path/to/opensim/bin/
# Or rename for consistent loading:
cp libBulletSim-*.dylib /path/to/opensim/bin/libBulletSim.dylib
```

**Windows:**

```batch
copy BulletSim\x64\Release\BulletSim.dll \path\to\opensim\bin\
```

### Configuration

Update `bin/OpenSim.Region.PhysicsModule.BulletS.dll.config` to reference the correct binary:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <startup>
    <!-- Update this path to match your BulletSim binary -->
    <PhysicsEngineLibrary path="libBulletSim-3.25-20260324-x86_64.so" />
  </startup>
</configuration>
```

---

## Notes

- **Bullet Version:** This repository uses Bullet 3.x from <https://github.com/bulletphysics/bullet3>
- **Legacy Support:** Bullet 2.x is no longer supported; use historical branches/tags if needed
- **Version Pinning:** Set `BULLET_REQUIRED_VERSION` to fail early if wrong version is detected
- **Multi-Build:** Use `BULLET_BUILD_DIRS` in `makeBullets.sh` to build multiple Bullet directories in one run
- **64-bit Only:** Only 64-bit systems (x86_64, aarch64, arm64) are supported

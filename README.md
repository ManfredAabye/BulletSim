# BulletSim Development Repository

**BulletSim-Version:** 1.4  
**Bullet-Version:** 3.27 (master branch)  
**Last Updated:** 2026-03-24  
**Status:** Fully migrated to Bullet 3.x (legacy 2.x support removed)

C++ wrapper for the [Bullet Physics Engine](https://github.com/bulletphysics/bullet3)
as used by the [OpenSimulator](http://opensimulator.org) BulletSim physics plugin.

This repository contains the C++ integration code (the "glue" layer) that binds the Bullet physics engine to OpenSimulator's C# physics plugin interface. It is maintained separately from the main OpenSim distribution for development, testing, and enhancement work.

## Supported Platforms

| Platform | Architecture | Status | Build Script |
| --- | --- | --- | --- |
| **Windows** | x64 | ✅ Fully supported | `02buildBulletCMake.bat` → `03buildBulletSim.bat` |
| **Linux** | x86_64, aarch64 | ✅ Fully supported | `l02buildBulletCMake.sh` → `l03buildBulletSim.sh` |
| **macOS** | arm64/x86_64 (universal) | ✅ Fully supported | `l02buildBulletCMake.sh` → `l03buildBulletSim.sh` |

## Build System

This repository uses a **CMake + MSBuild/Make** build pipeline:

- **Windows:** MSBuild (via Visual Studio 2022) + CMake for dependency building
- **Linux/macOS:** CMake + GNU Make/Clang

Build scripts are now platform-independent and self-documenting:

**Windows (numbered scripts, run in order):**

1. `01buildBulletClear.bat` — Clean previous build artifacts
2. `02buildBulletCMake.bat` — Build Bullet 3.x with CMake
3. `03buildBulletSim.bat` — Compile BulletSim C++ glue code with MSBuild

**Linux/macOS (prefixed with `l`):**

1. `l01buildBulletClear.sh` — Clean previous build artifacts
2. `l02buildBulletCMake.sh` — Build Bullet 3.x with CMake
3. `l03buildBulletSim.sh` — Compile libBulletSim.so/dylib with gcc/clang

## Quick Start

See [BUILD.md](BUILD.md) for detailed instructions, configuration options, and system requirements.

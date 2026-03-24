# BUILDING THINGS

The [Bullet physics engine](https://github.com/bulletphysics/bullet3) is
available for OpenSimulator using the BulletSim plugin. This functionality
is provided by several pre-built binary executables for various target
architectures. These executables include DLL's, SO's, and DYNLIB's.

BulletSim consists of the C# code that is included in the OpenSimulator
sources, this C++ "glue" code which provides the interface between the C# code
and the Bullet physics engine, and the Bullet physics engine itself.

The steps are to fetch the Bullet physics engine sources, build it, then
build the BulletSim C++ glue code and staticlly link it with the built
Bullet physics engine.

Since Bullet is supplied as a binary, there are separate versions built
for different target operating systems and machine architectures. Thus
the built binary filename includes the version of Bullet used, the build
date, and the target machine architecture. Expect to see filenames like:

- `libBulletSim-3.25-20260323-x86_64.so` (Intel arch, Linux)
- `libBulletSim-3.25-20260323-aarch64.so` (ARM 64 bit arch, Linux)
- `libBulletSim-3.25-20260323-universal.dynlib` (either x86 or ARM, IOS)
- `libBulletSim-3.25-20260323-x86.64.dll` (Intel arch, Windows)

The selection of which binary to use must be configured in OpenSimulator.
This either requires copying the correct file to as default name or
editing a `.config` file.

## NOTES

- This build flow supports Bullet 3.x source trees.
- Legacy Bullet 2.x build flows are intentionally removed from this repository.

- Only 64 bit architectures are supported.

## BUILDING

The current build flow is CMake + MSBuild for Windows C++ builds.

- Required on Windows: CMake, Git, Visual Studio 2022 (MSBuild + C++ toolchain).
- `dotnet build` is not used for the C++ `BulletSim.vcxproj` build.

The scripts are now version-flexible and are not hardcoded to one Bullet tree.

- Use `BULLETDIR` to select one Bullet source directory (default `bullet3`).
- Use `BULLET_BUILD_DIRS` in `makeBullets.sh` to build one or more Bullet 3.x source directories in one run.

### Quick Start (Linux/macOS)

1. Clone Bullet (or prepare multiple Bullet directories).

```bash
cd trunk/unmanaged/BulletSim
git clone --depth 1 --single-branch https://github.com/bulletphysics/bullet3.git
```

1. Build one Bullet directory plus BulletSim.

```bash
BULLETDIR=bullet3 ./buildBulletCMake.sh
./buildBulletSim.sh
```

1. Build multiple Bullet directories in one run.

```bash
BULLET_BUILD_DIRS="bullet3" ./makeBullets.sh
```

### Quick Start (Windows)

1. Optional: clean old artifacts.

```bat
01buildBulletClear.bat
```

1. Build Bullet with CMake.

```bat
set BULLETDIR=bullet3
02buildBulletCMake.bat
```

1. Build BulletSim.

```bat
03buildBulletSim.bat
```

Windows wrappers are numbered in execution order for easier usage:

- `01buildBulletClear.bat` cleans local build artifacts
- `02buildBulletCMake.bat` builds Bullet with CMake and copies headers/libs into this repo
- `03buildBulletSim.bat` builds `BulletSim.sln` with `MSBuild.exe`
- `buildBulletVS.bat` is a legacy premake-based helper and is not part of the recommended flow

### Optional Build Parameters

- `BULLET_REQUIRED_VERSION`:
    Optional exact version pin (for example `3.52`). If unset, any Bullet `3.x` version is accepted.
- `TARGET_BULLET_TAG`:
    Optional git tag/branch/commit to checkout when `FETCHBULLETSOURCES=yes` in `makeBullets.sh`.
- `BULLETDIR`:
    Bullet source directory to build.
- `BULLET_BUILD_DIRS`:
    Space-separated list of Bullet source directories for `makeBullets.sh`.
- `BULLETMACH`:
    Target machine architecture for Windows CMake (`x64` by default).
- `BULLETCMAKE_GENERATOR`:
    CMake generator override on Windows (default: `Visual Studio 17 2022`).
- `BULLETCMAKE_ARGS`:
    Additional CMake arguments passed through in `02buildBulletCMake.bat`.

### Compatibility Matrix

| Scenario | Bullet source directories | Linux/macOS command | Windows command |
| --- | --- | --- | --- |
| Default Bullet 3.x | `bullet3` | `BULLETDIR=bullet3 ./buildBulletCMake.sh && ./buildBulletSim.sh` | `set BULLETDIR=bullet3 && 02buildBulletCMake.bat && 03buildBulletSim.bat` |
| Multiple 3.x trees in one run | e.g. `bullet3 bullet3-custom` | `BULLET_BUILD_DIRS="bullet3 bullet3-custom" ./makeBullets.sh` | Run per tree: set `BULLETDIR` and execute `02buildBulletCMake.bat` then `03buildBulletSim.bat` |
| Custom Bullet 3.x directory name | e.g. `bullet3-ci` | `BULLETDIR=bullet3-ci ./buildBulletCMake.sh && ./buildBulletSim.sh` | `set BULLETDIR=bullet3-ci && 02buildBulletCMake.bat && 03buildBulletSim.bat` |

Notes:

- Any directory listed above must exist and contain a valid Bullet source tree.
- `02buildBulletCMake.bat` auto-clones `bullet3` if the selected `BULLETDIR` does not exist.

### Output

The Linux/macOS build produces shared libraries with names like:

- `libBulletSim-3.25-20260323-x86_64.so`

Copy the resulting binary to the OpenSimulator runtime (`bin/lib64` on Linux)
and point `OpenSim.Region.PhysicsModule.BulletS.dll.config` to the correct
file for the running architecture.

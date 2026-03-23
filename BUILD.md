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

- `libBulletSim-3.25-20230122-x86_64.so` (Intel arch, Linux)
- `libBulletSim-3.25-20230122-aarch64.so` (ARM 64 bit arch, Linux)
- `libBulletSim-3.25-20230122-universal.dynlib` (either x86 or ARM, IOS)
- `libBulletSim-3.25-20230122-x86.64.dll` (Intel arch, Windows)

The selection of which binary to use must be configured in OpenSimulator.
This either requires copying the correct file to as default name or
editing a `.config` file.

## NOTES

- This builds with Bullet physics engine version 3+. Before 2023,
  `BulletSim.dll` was built with Bullet version 2.86. The 3.25 version
  of Bullet has been tested and does not seem to make any
  difference to OpenSimulator operation as most of the Bullet changes
  have to do with APIs and integration with Python (thus PyBullet).
  Refer to some of the `.sh` files for the process of building the
  BulletSim binary with the previous version of Bullet.

- Only 64 bit architectures are supported.

## BUILDING

The current build scripts are Dotnet 8 first.

- Required SDK: Dotnet 8 or newer.
- Optional override: set `DOTNET_REQUIRED_MAJOR` if a different major is needed.

The scripts are now version-flexible and are not hardcoded to one Bullet tree.

- Use `BULLETDIR` to select one Bullet source directory (for example `bullet3`, `bullet2`, `bullet325`).
- Use `BULLET_BUILD_DIRS` in `makeBullets.sh` to build several Bullet directories in one run.

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
BULLET_BUILD_DIRS="bullet2 bullet3" ./makeBullets.sh
```

### Quick Start (Windows)

1. Build Bullet with CMake using PowerShell.

```powershell
$env:BULLETDIR = "bullet3"
./buildBulletCMake.ps1
```

1. Build BulletSim.

```powershell
./buildBulletSim.ps1
```

Batch wrappers are available:

- `buildBulletCMake.bat` calls `buildBulletCMake.ps1`
- `buildBulletSim.bat` builds BulletSim with the same Dotnet checks

### Optional Build Parameters

- `DOTNET_REQUIRED_MAJOR`:
    Minimum required Dotnet SDK major version. Default is `8`.
- `BULLETDIR`:
    Bullet source directory to build.
- `BULLET_BUILD_DIRS`:
    Space-separated list of Bullet source directories for `makeBullets.sh`.
- `BULLETMACH`:
    Target machine architecture for Windows CMake (`x64` by default).
- `BULLETCMAKE_GENERATOR`:
    CMake generator override on Windows (default: `Visual Studio 17 2022`).
- `BULLETCMAKE_ARGS`:
    Additional CMake arguments passed through in `buildBulletCMake.ps1`.

### Compatibility Matrix

| Scenario | Bullet source directories | Linux/macOS command | Windows command |
| --- | --- | --- | --- |
| Single current Bullet | `bullet3` | `BULLETDIR=bullet3 ./buildBulletCMake.sh && ./buildBulletSim.sh` | `$env:BULLETDIR="bullet3"; ./buildBulletCMake.ps1; ./buildBulletSim.ps1` |
| Legacy Bullet 2.86 style tree | `bullet2` | `BULLETDIR=bullet2 ./buildBulletCMake.sh && ./buildBulletSim.sh` | `$env:BULLETDIR="bullet2"; ./buildBulletCMake.ps1; ./buildBulletSim.ps1` |
| Multiple Bullet trees in one run | `bullet2 bullet3` | `BULLET_BUILD_DIRS="bullet2 bullet3" ./makeBullets.sh` | Run per tree: set `$env:BULLETDIR` and execute `buildBulletCMake.ps1` then `buildBulletSim.ps1` |
| Custom Bullet directory name | e.g. `bullet325` | `BULLETDIR=bullet325 ./buildBulletCMake.sh && ./buildBulletSim.sh` | `$env:BULLETDIR="bullet325"; ./buildBulletCMake.ps1; ./buildBulletSim.ps1` |

Notes:

- Any directory listed above must exist and contain a valid Bullet source tree.
- Use `DOTNET_REQUIRED_MAJOR` if you need to enforce a different minimum Dotnet SDK major than `8`.

### Output

The Linux/macOS build produces shared libraries with names like:

- `libBulletSim-3.25-20230111-x86_64.so`

Copy the resulting binary to the OpenSimulator runtime (`bin/lib64` on Linux)
and point `OpenSim.Region.PhysicsModule.BulletS.dll.config` to the correct
file for the running architecture.

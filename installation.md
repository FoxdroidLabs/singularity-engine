# Singularity Engine

A custom 3D game engine built in Zig with Vulkan rendering.

## Prerequisites

- [Zig 0.16.0](https://ziglang.org/download/), exact version required
- Vulkan SDK (up-to-date Vulkan drivers)
- Git

## Dependencies

Dependencies are managed via `build.zig.zon` and fetched automatically:

- [vulkan-zig](https://github.com/Snektron/vulkan-zig), Vulkan bindings for Zig
- [zglfw](https://github.com/zig-gamedev/zglfw), GLFW bindings for Zig

## Installation

```sh
git clone https://github.com/your-repo/singularity-engine
cd singularity-engine
```

## Build

```sh
For linux:
zig build

For linux from Windows :
zig build -Dtarget=x86_64-linux

For windows:
zig build -Dnosubsystem (The -Dnosubsystem remove the console log from when you launch the binary)

For Windows From Linux :
zig build -Dnosubsystem -Dtarget=x86_64-windows
```

## Run

Use the ./setup.sh or ./setup.bat, cause of the shaders you need to setup due to the hardcoded folders etc
then run it from the folder or the Windows Menu and for linux a .desktop is created by default :
./setup.sh for linux
./setup.bat for windows

## Setup

A setup script for linux is available if needed:
It add the engine to a specific folder (you can choose) and will create a .desktop file with the good icon

```sh
chmod +x setup.sh
./setup.sh
```

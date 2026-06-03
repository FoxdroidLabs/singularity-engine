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

For windows:
zig build -Dnosubsystem (The -Dnosubsystem remove the console log from when you launch the binary)
```

## Run

```sh
zig build run-engine
```

## Setup

A setup script for linux is available if needed:
It add the engine to a specific folder (you can choose) and will create a .desktop file with the good icon

```sh
chmod +x setup.sh
./setup.sh
```

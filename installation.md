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
zig build
```

## Run

```sh
zig build run-engine
```

## Setup

A setup script is available if needed:

```sh
./setup.sh
``

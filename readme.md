# Singularity Engine

> Open-source 3D engine built from scratch by [Foxdroid Labs](https://github.com/FoxdroidLabs).

## Stack

| Component    | Details                   |
| ------------ | ------------------------- |
| Language     | Zig 0.16.0                |
| Graphics API | Vulkan (via `vulkan-zig`) |
| Windowing    | GLFW (via `zglfw`)        |

## Philosophy

Everything is built from scratch, no third-party libs except Vulkan and GLFW.

## Roadmap

### Core

- [x] Tick system
- [x] Game loop
- [x] Window
- [ ] Input manager
- [ ] Camera controller

### Rendering

- [9/9] Vulkan bootstrap
  - [x] Instance & validation layers
  - [x] Physical & logical device
  - [x] Swapchain
  - [x] Render pass
  - [x] Framebuffers
  - [x] Graphics pipeline
  - [x] Command pool & command buffers
  - [x] Synchronization
  - [x] Draw loop
- [x] Vertex buffers & mesh loading (OBJ)
- [x] Camera & MVP matrices
- [x] Depth buffer
- [x] Custom lighting model (Phong)
- [ ] Textures & UV mapping
- [ ] Free camera (WASD + mouse)
- [ ] VRAM optimization
- [ ] Nanite-like LOD system

### Performance

- [ ] Multi-threaded tick
- [ ] Multi-threaded physics
- [ ] GPU-accelerated particles
- [ ] Multi-threaded ray tracing _(disabled by default)_
- [ ] Light baking

### Engine

- [ ] ECS (Entity Component System)
- [ ] Scene graph
- [ ] Asset manager (OBJ loader ✓)
- [ ] Custom physics plugin
- [ ] GPU UI rendering
- [ ] Multi-threaded viewport

## Project Structure

`structure.md`

## Utils

```sh
# Count lines of Zig source (Linux only)
find . -type f -name '*.zig' -not -path '*/.zig-cache/*' -not -path '*/zig-pkg/*' -print0 | xargs -0 wc -l

# Count chars of Zig source (Linux only)
find . -type f -name '*.zig' -not -path '*/.zig-cache/*' -not -path '*/zig-pkg/*' -print0 | xargs -0 wc -c
```

---

_Foxdroid Labs_

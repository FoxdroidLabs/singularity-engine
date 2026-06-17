# Singularity Engine

> Open-source 3D engine built from scratch by [Foxdroid Labs](https://github.com/FoxdroidLabs).

## Stack

| Component    | Details                   |
| ------------ | ------------------------- |
| Language     | Zig 0.16.0                |
| Graphics API | Vulkan (via `vulkan-zig`) |
| Windowing    | GLFW (via `zglfw`)        |
| Images       | `zigimg`                  |

## Philosophy

Everything is built from scratch. Third-party libs are kept to a minimum (Vulkan, GLFW, image loading), math, parsing, physics, audio, and editor tooling are homemade.

## Roadmap

### Core

- [x] Tick system
- [x] Game loop
- [x] Window
- [x] Input manager
- [x] Free camera (WASD + mouse)
- [ ] Settings system (resolution, fov, keybinds)

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
- [x] Textures & UV mapping
- [ ] Skeletal animation (bones, skinning, keyframes)
- [ ] Shadow mapping
- [ ] PBR materials
- [ ] Post-processing (bloom, tone mapping, FXAA)
- [ ] VRAM optimization (staging buffers, device-local memory)
- [ ] Nanite-like LOD system

### Audio

- [ ] Audio engine core (mixing, playback)
- [ ] Ray-traced audio (occlusion, reverb via geometry)
- [ ] Spatial/3D audio

### Performance

- [ ] Multi-threaded tick
- [ ] Multi-threaded physics
- [ ] GPU-accelerated particles
- [ ] Ray tracing library _(separate optional lib, disabled by default)_
- [ ] Light baking

### Engine

- [ ] ECS (Entity Component System)
- [ ] Scene graph
- [ ] Asset manager (OBJ loader ✓, texture loader ✓)
- [ ] Custom physics plugin
- [ ] GPU UI rendering
- [ ] Multi-threaded viewport

### Editor

- [ ] Viewport (gizmos, transform tools)
- [ ] Scene hierarchy panel
- [ ] Inspector (entity/component properties)
- [ ] File explorer
- [ ] Integrated terminal
- [ ] Shader editor (live WGSL editing + hot-reload)
- [ ] Texture editor
- [ ] Animation editor (skeletal, timeline, keyframes)

### Tooling

- [ ] Shader hot-reload
- [ ] Unit tests (math, OBJ/parsing)
- [ ] zig fmt compliance pass

### Scripting

- [ ] Blueprint/visual scripting system (node graph)
- [ ] Zig codegen from blueprint graphs (primary target)
- [ ] C codegen from blueprint graphs (secondary target)

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

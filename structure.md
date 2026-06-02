.
├── .gitignore
├── assets
│   ├── app.rc
│   ├── singularity.ico
│   └── singularity.png
├── build.zig
├── build.zig.zon
├── installation.md
├── readme.md
├── registry
│   └── vk.xml
├── setup.sh
└── src
    ├── core
    │   ├── core.zig
    │   ├── light
    │   │   └── light.zig
    │   ├── physic
    │   │   └── physic.zig
    │   ├── sound
    │   │   └── sound.zig
    │   ├── vulkan
    │   │   ├── shaders
    │   │   │   ├── main.frag
    │   │   │   └── main.vert
    │   │   ├── vk_command_buffer.zig
    │   │   ├── vk_context.zig
    │   │   ├── vk_draw.zig
    │   │   ├── vk_framebuffer.zig
    │   │   ├── vk_graphics_pipeline.zig
    │   │   ├── vk_logical_device.zig
    │   │   ├── vk_physical_device.zig
    │   │   ├── vk_renderpass.zig
    │   │   ├── vk_surface.zig
    │   │   ├── vk_swapchain.zig
    │   │   └── vk_sync.zig
    │   └── window
    │       ├── icon16.raw
    │       ├── icon32.raw
    │       ├── icon48.raw
    │       └── window.zig
    ├── editor
    │   ├── editor.zig
    │   ├── explorer
    │   │   └── explorer.zig
    │   ├── terminal
    │   │   └── terminal.zig
    │   └── viewport
    │       └── viewport.zig
    ├── engine
    │   ├── system.zig
    │   └── tick.zig
    ├── libs
    │   ├── discord
    │   │   ├── discord.zig
    │   │   ├── ipc.zig
    │   │   └── presence.zig
    │   └── libs.zig
    ├── main.zig
    └── root.zig
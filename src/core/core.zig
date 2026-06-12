const std = @import("std");
pub const vk = @import("vulkan");
pub const glfw = @import("zglfw");

// Import all the Vulkan Necessary backend
pub const VulkanContext = @import("./vulkan/vk_context.zig").VulkanContext;
pub const VulkanSurface = @import("./vulkan/vk_surface.zig").VulkanSurface;
pub const VulkanPhysicalDevice = @import("./vulkan/vk_physical_device.zig").VulkanPhysDevice;
pub const VulkanLogDevice = @import("./vulkan/vk_logical_device.zig").VulkanLogDevice;
pub const VulkanSwapchain = @import("./vulkan/vk_swapchain.zig").VulkanSwapchain;
pub const VulkanRenderpass = @import("./vulkan/vk_renderpass.zig").VulkanRenderpass;
pub const VulkanFramebuffer = @import("./vulkan/vk_framebuffer.zig").VulkanFramebuffer;
pub const VulkanDepth = @import("./vulkan/vk_depth.zig").VulkanDepth;
pub const VulkanGraphicsPipeline = @import("./vulkan/vk_graphics_pipeline.zig").VulkanGraphicsPipeline;
pub const VulkanCommandBuffer = @import("./vulkan/vk_command_buffer.zig").VulkanCommandBuffer;
pub const VulkanVertexBuffer = @import("./vulkan/vk_vertex_buffer.zig").VulkanVertexBuffer;
pub const VulkanIndexBuffer = @import("./vulkan/vk_index_buffer.zig").VulkanIndexBuffer;
pub const VulkanUniformBuffer = @import("./vulkan/vk_uniform_buffer.zig").VulkanUniformBuffer;
pub const VulkanDescriptor = @import("./vulkan/vk_descriptor.zig").VulkanDescriptor;
pub const VulkanSync = @import("./vulkan/vk_sync.zig").VulkanSync;
pub const MAX_FRAMES_IN_FLIGHT = @import("./vulkan/vk_sync.zig").MAX_FRAMES_IN_FLIGHT;
pub const VulkanDraw = @import("./vulkan/vk_draw.zig").VulkanDraw;
pub const Window = @import("./window/window.zig").Window;

// A Core
pub const Core = struct {
    vkcontext: VulkanContext,
    vksurface: VulkanSurface,
    vkphysicaldevice: VulkanPhysicalDevice,
    vklogicaldevice: VulkanLogDevice,
    vkswapchain: VulkanSwapchain,
    vkdepth: VulkanDepth,
    vkrenderpass: VulkanRenderpass,
    vkframebuffer: VulkanFramebuffer,
    vkuniformbuffer: VulkanUniformBuffer,
    vkdescriptor: VulkanDescriptor,
    vkgraphicspipeline: VulkanGraphicsPipeline,
    vkcommandbuffer: VulkanCommandBuffer,
    vkvertexbuffer: VulkanVertexBuffer,
    vkindexbuffer: VulkanIndexBuffer,
    vksync: VulkanSync,
    window: Window,

    pub fn init(io: std.Io, allocator: std.mem.Allocator) !Core {

        // Just an hardcoded triangle
        const vertices = [_]VulkanVertexBuffer.Vertex{
            .{ .pos = .{ 0.0, -0.5, 0.0 }, .color = .{ 1.0, 0.0, 0.0 } },
            .{ .pos = .{ 0.5, 0.5, 0.0 }, .color = .{ 0.0, 1.0, 0.0 } },
            .{ .pos = .{ -0.5, 0.5, 0.0 }, .color = .{ 0.0, 0.0, 1.0 } },
        };
        const indices = [_]u16{ 0, 1, 2, 2, 3, 0 };

        var core: Core = undefined;
        try glfw.init();

        // Init all the vulkan backend code (it's working rn don't touch)
        core.vkcontext = try VulkanContext.init();
        core.vkcontext.instance = vk.InstanceProxy.init(core.vkcontext.instance.handle, &core.vkcontext.vki);
        core.window = try Window.init();
        core.vksurface = try VulkanSurface.init(core.vkcontext.instance.handle, core.window.handle);
        core.vkphysicaldevice = try VulkanPhysicalDevice.init(&core.vkcontext.instance, allocator);
        core.vklogicaldevice = try VulkanLogDevice.init(core.vkcontext.instance, core.vkphysicaldevice.handle, core.vksurface.surface, allocator);
        core.vklogicaldevice.handle = vk.DeviceProxy.init(core.vklogicaldevice.handle.handle, &core.vklogicaldevice.vkd);
        core.vkswapchain = try VulkanSwapchain.init(core.vkcontext.instance, core.vkphysicaldevice.handle, &core.vklogicaldevice.handle, core.vksurface.surface, core.window.handle, allocator);
        core.vkdepth = try VulkanDepth.init(&core.vklogicaldevice.handle, core.vkswapchain.extent, core.vkcontext.instance, core.vkphysicaldevice.handle);
        core.vkrenderpass = try VulkanRenderpass.init(&core.vklogicaldevice.handle, core.vkswapchain.image_format, core.vkdepth.format);
        core.vkframebuffer = try VulkanFramebuffer.init(allocator, &core.vklogicaldevice.handle, core.vkrenderpass.handle, core.vkswapchain.images_view, core.vkdepth.depth_view, core.vkswapchain.extent);
        core.vkuniformbuffer = try VulkanUniformBuffer.init(core.vkcontext.instance, core.vkphysicaldevice.handle, &core.vklogicaldevice.handle, MAX_FRAMES_IN_FLIGHT);
        core.vkdescriptor = try VulkanDescriptor.init(allocator, &core.vklogicaldevice.handle, &core.vkuniformbuffer, MAX_FRAMES_IN_FLIGHT);
        core.vkgraphicspipeline = try VulkanGraphicsPipeline.init(io, allocator, &core.vklogicaldevice.handle, core.vkrenderpass.handle, core.vkdescriptor.layout, .{});
        core.vkcommandbuffer = try VulkanCommandBuffer.init(&core.vklogicaldevice.handle, core.vklogicaldevice.graphics_family, core.vkrenderpass.handle, core.vkgraphicspipeline.pipeline, core.vkgraphicspipeline.layout, core.vkswapchain.extent);
        core.vkvertexbuffer = try VulkanVertexBuffer.init(core.vkcontext.instance, core.vkphysicaldevice.handle, &core.vklogicaldevice.handle, &vertices);
        core.vkindexbuffer = try VulkanIndexBuffer.init(core.vkcontext.instance, core.vkphysicaldevice.handle, &core.vklogicaldevice.handle, &indices);
        core.vksync = try VulkanSync.init(&core.vklogicaldevice.handle, allocator, core.vkswapchain.images_view.len);

        core.window.setIcon();
        glfw.pollEvents();
        return core;
    }

    // Allow to the window to be resized in Windows NT kernel based OS, or Linux Kernel Based OS
    pub fn recreateSwapchain(self: *Core, io: std.Io, allocator: std.mem.Allocator) !void {
        self.vklogicaldevice.handle = vk.DeviceProxy.init(self.vklogicaldevice.handle.handle, &self.vklogicaldevice.vkd);
        self.vkcontext.instance = vk.InstanceProxy.init(self.vkcontext.instance.handle, &self.vkcontext.vki);
        _ = self.vklogicaldevice.handle.deviceWaitIdle() catch {};

        self.vkcommandbuffer.deinit(&self.vklogicaldevice.handle);
        self.vkframebuffer.deinit(&self.vklogicaldevice.handle);
        self.vkdepth.deinit(&self.vklogicaldevice.handle);
        self.vkgraphicspipeline.deinit(&self.vklogicaldevice.handle);
        self.vksync.deinit(&self.vklogicaldevice.handle);
        self.vkswapchain.deinit(self.vklogicaldevice.handle, allocator);

        self.vkswapchain = try VulkanSwapchain.init(self.vkcontext.instance, self.vkphysicaldevice.handle, &self.vklogicaldevice.handle, self.vksurface.surface, self.window.handle, allocator);
        self.vkdepth = try VulkanDepth.init(&self.vklogicaldevice.handle, self.vkswapchain.extent, self.vkcontext.instance, self.vkphysicaldevice.handle);
        self.vksync = try VulkanSync.init(&self.vklogicaldevice.handle, allocator, self.vkswapchain.images_view.len);
        self.vkgraphicspipeline = try VulkanGraphicsPipeline.init(io, allocator, &self.vklogicaldevice.handle, self.vkrenderpass.handle, self.vkdescriptor.layout, .{});
        self.vkframebuffer = try VulkanFramebuffer.init(allocator, &self.vklogicaldevice.handle, self.vkrenderpass.handle, self.vkswapchain.images_view, self.vkdepth.depth_view, self.vkswapchain.extent);
        self.vkcommandbuffer = try VulkanCommandBuffer.init(&self.vklogicaldevice.handle, self.vklogicaldevice.graphics_family, self.vkrenderpass.handle, self.vkgraphicspipeline.pipeline, self.vkgraphicspipeline.layout, self.vkswapchain.extent);
    }

    // I guess it draw something ?
    pub fn draw(self: *Core, io: std.Io, allocator: std.mem.Allocator) !void {
        const fb_size = self.window.handle.getFramebufferSize();
        const fb_w: u32 = @intCast(fb_size[0]);
        const fb_h: u32 = @intCast(fb_size[1]);
        if (fb_w != self.vkswapchain.extent.width or fb_h != self.vkswapchain.extent.height) {
            try self.recreateSwapchain(io, allocator);
            return;
        }
        const needs_recreate = try VulkanDraw.draw(
            &self.vklogicaldevice.handle,
            self.vkswapchain.handle,
            &self.vksync,
            self.vklogicaldevice.present_queue,
            self.vklogicaldevice.graphics_queue,
            &self.vkcommandbuffer,
            self.vkframebuffer.handles,
            &self.vkvertexbuffer,
            &self.vkdescriptor,
        );
        if (needs_recreate) try self.recreateSwapchain(io, allocator);
    }

    // We love memory and we want it free
    pub fn deinit(self: *Core, allocator: std.mem.Allocator) void {
        _ = self.vklogicaldevice.handle.deviceWaitIdle() catch {};
        self.vksync.deinit(&self.vklogicaldevice.handle);
        self.vkdescriptor.deinit(&self.vklogicaldevice.handle);
        self.vkuniformbuffer.deinit(&self.vklogicaldevice.handle);
        self.vkindexbuffer.deinit(&self.vklogicaldevice.handle);
        self.vkvertexbuffer.deinit(&self.vklogicaldevice.handle);
        self.vkcommandbuffer.deinit(&self.vklogicaldevice.handle);
        self.vkgraphicspipeline.deinit(&self.vklogicaldevice.handle);
        self.vkdepth.deinit(&self.vklogicaldevice.handle);
        self.vkframebuffer.deinit(&self.vklogicaldevice.handle);
        self.vkrenderpass.deinit(&self.vklogicaldevice.handle);
        self.vkswapchain.deinit(self.vklogicaldevice.handle, allocator);
        self.vklogicaldevice.handle.destroyDevice(null);
        self.vksurface.deinit(self.vkcontext.instance);
        self.vkcontext.deinit();
        self.window.deinit();
        glfw.terminate();
    }
};

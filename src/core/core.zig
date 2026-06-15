const std = @import("std");
pub const vk = @import("vulkan");
pub const glfw = @import("zglfw");
pub const zigimg = @import("zigimg");
pub const math = @import("./math/math.zig");

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
pub const Mesh = @import("./vulkan/vk_mesh.zig").Mesh;
pub const Textures = @import("./vulkan/vk_textures.zig").Textures;
pub const Window = @import("./window/window.zig").Window;

fn glfwErrorCallback(code: glfw.ErrorCode, desc: ?[*:0]const u8) callconv(.c) void {
    const message = if (desc) |msg| std.mem.span(msg) else "No GLFW error description.";
    std.log.err("GLFW error {d}: {s}", .{ code, message });
}

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
    start_time: std.Io.Timestamp,
    mesh: Mesh,
    textures: Textures,

    pub fn init(self: *Core, io: std.Io, allocator: std.mem.Allocator) !void {
        _ = glfw.setErrorCallback(glfwErrorCallback);
        try glfw.init();
        errdefer glfw.terminate();

        self.window = try Window.init();
        errdefer self.window.deinit();

        try self.initVulkan(io, allocator);

        self.start_time = std.Io.Clock.now(.awake, io);
        self.window.setIcon();
        glfw.pollEvents();
    }

    fn initVulkan(self: *Core, io: std.Io, allocator: std.mem.Allocator) !void {
        self.vkcontext = try VulkanContext.init();
        self.vkcontext.instance = vk.InstanceProxy.init(self.vkcontext.instance.handle, &self.vkcontext.vki);
        errdefer self.vkcontext.deinit();

        self.vksurface = try VulkanSurface.init(self.vkcontext.instance.handle, self.window.handle);
        errdefer self.vksurface.deinit(self.vkcontext.instance);

        self.vkphysicaldevice = try VulkanPhysicalDevice.init(&self.vkcontext.instance, allocator);

        self.vklogicaldevice = try VulkanLogDevice.init(self.vkcontext.instance, self.vkphysicaldevice.handle, self.vksurface.surface, allocator);
        self.vklogicaldevice.handle = vk.DeviceProxy.init(self.vklogicaldevice.handle.handle, &self.vklogicaldevice.vkd);
        errdefer self.vklogicaldevice.handle.destroyDevice(null);

        self.vkswapchain = try VulkanSwapchain.init(self.vkcontext.instance, self.vkphysicaldevice.handle, &self.vklogicaldevice.handle, self.vksurface.surface, self.window.handle, allocator);
        errdefer self.vkswapchain.deinit(self.vklogicaldevice.handle, allocator);

        self.vkdepth = try VulkanDepth.init(&self.vklogicaldevice.handle, self.vkswapchain.extent, self.vkcontext.instance, self.vkphysicaldevice.handle);
        errdefer self.vkdepth.deinit(&self.vklogicaldevice.handle);

        self.vkrenderpass = try VulkanRenderpass.init(&self.vklogicaldevice.handle, self.vkswapchain.image_format, self.vkdepth.format);
        errdefer self.vkrenderpass.deinit(&self.vklogicaldevice.handle);

        self.vkframebuffer = try VulkanFramebuffer.init(allocator, &self.vklogicaldevice.handle, self.vkrenderpass.handle, self.vkswapchain.images_view, self.vkdepth.depth_view, self.vkswapchain.extent);
        errdefer self.vkframebuffer.deinit(&self.vklogicaldevice.handle);

        self.vkuniformbuffer = try VulkanUniformBuffer.init(self.vkcontext.instance, self.vkphysicaldevice.handle, &self.vklogicaldevice.handle, MAX_FRAMES_IN_FLIGHT);
        errdefer self.vkuniformbuffer.deinit(&self.vklogicaldevice.handle);

        self.vkdescriptor = try VulkanDescriptor.init(allocator, &self.vklogicaldevice.handle, &self.vkuniformbuffer, MAX_FRAMES_IN_FLIGHT);
        errdefer self.vkdescriptor.deinit(&self.vklogicaldevice.handle);

        self.vkgraphicspipeline = try VulkanGraphicsPipeline.init(io, allocator, &self.vklogicaldevice.handle, self.vkrenderpass.handle, self.vkdescriptor.layout, .{});
        errdefer self.vkgraphicspipeline.deinit(&self.vklogicaldevice.handle);

        self.vkcommandbuffer = try VulkanCommandBuffer.init(&self.vklogicaldevice.handle, self.vklogicaldevice.graphics_family, self.vkrenderpass.handle, self.vkgraphicspipeline.pipeline, self.vkgraphicspipeline.layout, self.vkswapchain.extent);
        errdefer self.vkcommandbuffer.deinit(&self.vklogicaldevice.handle);

        self.mesh = try Mesh.load(io, allocator, self.vkcontext.instance, self.vkphysicaldevice.handle, &self.vklogicaldevice.handle, "cube");
        errdefer self.mesh.deinit(&self.vklogicaldevice.handle);
        self.vkvertexbuffer = self.mesh.vertex_buffer;
        self.vkindexbuffer = self.mesh.index_buffer;

        self.textures = try Textures.init(io, allocator, "cube");
        //errdefer self.textures.deinit(&self.vklogicaldevice.handle);

        self.vksync = try VulkanSync.init(&self.vklogicaldevice.handle, allocator, self.vkswapchain.images_view.len);
        errdefer self.vksync.deinit(&self.vklogicaldevice.handle);
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
    pub fn draw(self: *Core, io: std.Io, allocator: std.mem.Allocator, view: [4][4]f32) !void {
        const fb_size = self.window.handle.getFramebufferSize();
        const fb_w: u32 = @intCast(fb_size[0]);
        const fb_h: u32 = @intCast(fb_size[1]);
        if (fb_w != self.vkswapchain.extent.width or fb_h != self.vkswapchain.extent.height) {
            try self.recreateSwapchain(io, allocator);
            return;
        }
        const now = std.Io.Clock.now(.awake, io);
        const elapsed = @as(f32, @floatFromInt(self.start_time.durationTo(now).toNanoseconds())) / 1_000_000_000.0;
        const needs_recreate = try VulkanDraw.draw(
            &self.vklogicaldevice.handle,
            self.vkswapchain.handle,
            &self.vksync,
            self.vklogicaldevice.present_queue,
            self.vklogicaldevice.graphics_queue,
            &self.vkcommandbuffer,
            self.vkframebuffer.handles,
            &self.vkvertexbuffer,
            &self.vkindexbuffer,
            &self.vkuniformbuffer,
            &self.vkdescriptor,
            view,
            elapsed,
        );
        if (needs_recreate) try self.recreateSwapchain(io, allocator);
    }

    // We love memory and we want it free
    pub fn deinit(self: *Core, allocator: std.mem.Allocator) void {
        _ = self.vklogicaldevice.handle.deviceWaitIdle() catch {};
        self.vksync.deinit(&self.vklogicaldevice.handle);
        self.vkdescriptor.deinit(&self.vklogicaldevice.handle);
        self.vkuniformbuffer.deinit(&self.vklogicaldevice.handle);
        //self.texture.deinit(&self.vklogicaldevice.handle);
        self.mesh.deinit(&self.vklogicaldevice.handle);
        self.vkcommandbuffer.deinit(&self.vklogicaldevice.handle);
        self.vkgraphicspipeline.deinit(&self.vklogicaldevice.handle);
        self.vkframebuffer.deinit(&self.vklogicaldevice.handle);
        self.vkdepth.deinit(&self.vklogicaldevice.handle);
        self.vkrenderpass.deinit(&self.vklogicaldevice.handle);
        self.vkswapchain.deinit(self.vklogicaldevice.handle, allocator);
        self.vklogicaldevice.handle.destroyDevice(null);
        self.vksurface.deinit(self.vkcontext.instance);
        self.vkcontext.deinit();
        self.window.deinit();
        glfw.terminate();
    }
};

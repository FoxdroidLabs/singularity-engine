const std = @import("std");
pub const vk = @import("vulkan");
pub const glfw = @import("zglfw");
pub const zigimg = @import("zigimg");
pub const math = @import("./math/math.zig");

// Import all the Vulkan Necessary backend
pub const VulkanContext = @import("./vulkan/vk_context.zig").VulkanContext;
pub const VulkanRenderContext = @import("./vulkan/vk_render_context.zig").VulkanRenderContext;
pub const VulkanSurface = @import("./vulkan/vk_surface.zig").VulkanSurface;
pub const VulkanPhysicalDevice = @import("./vulkan/vk_physical_device.zig").VulkanPhysDevice;
pub const VulkanLogDevice = @import("./vulkan/vk_logical_device.zig").VulkanLogDevice;
pub const VulkanSwapchain = @import("./vulkan/vk_swapchain.zig").VulkanSwapchain;
pub const VulkanRenderpass = @import("./vulkan/vk_renderpass.zig").VulkanRenderpass;
pub const VulkanFramebuffer = @import("./vulkan/vk_framebuffer.zig").VulkanFramebuffer;
pub const VulkanDepth = @import("./vulkan/vk_depth.zig").VulkanDepth;
pub const VulkanGraphicsPipeline = @import("./vulkan/vk_graphics_pipeline.zig").VulkanGraphicsPipeline;
pub const PipelineConfig = @import("./vulkan/vk_graphics_pipeline.zig").PipelineConfig;
pub const VulkanCommand = @import("./vulkan/vk_command_buffer.zig");
pub const VulkanCommandBuffer = VulkanCommand.VulkanCommandBuffer;
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

// A Core
pub const Core = struct {
    vkuniformbuffer: VulkanUniformBuffer,
    vkdescriptor: VulkanDescriptor,
    vkgraphicspipeline: VulkanGraphicsPipeline,
    vkcommandbuffer: VulkanCommandBuffer,
    vkvertexbuffer: VulkanVertexBuffer,
    vkindexbuffer: VulkanIndexBuffer,
    start_time: std.Io.Timestamp,
    mesh: Mesh,
    textures: Textures,
    last_resize_time: ?std.Io.Timestamp = null,
    pending_size: ?Window.ResizeEvent = null,

    pub fn init(self: *Core, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        try self.initVulkan3D(io, allocator, render_context);
        self.start_time = std.Io.Clock.now(.awake, io);
    }

    fn initPipelineAndCommands(self: *Core, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        self.vkgraphicspipeline = try VulkanGraphicsPipeline.init(io, allocator, &render_context.vklogicaldevice.handle, render_context.vkrenderpass.handle, .{
            .descriptor_set_layouts = &[_]vk.DescriptorSetLayout{self.vkdescriptor.layout},
            .vertex_bindings = &[_]vk.VertexInputBindingDescription{VulkanVertexBuffer.binding},
            .vertex_attributes = VulkanVertexBuffer.attributes[0..],
        });
        errdefer self.vkgraphicspipeline.deinit(&render_context.vklogicaldevice.handle);

        self.vkcommandbuffer = try VulkanCommandBuffer.init(&render_context.vklogicaldevice.handle, render_context.vklogicaldevice.graphics_family, render_context.vkrenderpass.handle, self.vkgraphicspipeline.pipeline, self.vkgraphicspipeline.layout, render_context.vkswapchain.extent);
        errdefer self.vkcommandbuffer.deinit(&render_context.vklogicaldevice.handle);
    }

    fn initVulkan3D(self: *Core, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        self.vkuniformbuffer = try VulkanUniformBuffer.init(render_context.vkcontext.instance, render_context.vkphysicaldevice.handle, &render_context.vklogicaldevice.handle, MAX_FRAMES_IN_FLIGHT);
        errdefer self.vkuniformbuffer.deinit(&render_context.vklogicaldevice.handle);

        // Mesh loaded early, no dependency on pipeline/descriptor
        self.mesh = try Mesh.load(io, allocator, render_context.vkcontext.instance, render_context.vkphysicaldevice.handle, &render_context.vklogicaldevice.handle, "cube");
        errdefer self.mesh.deinit(&render_context.vklogicaldevice.handle);
        self.vkvertexbuffer = self.mesh.vertex_buffer;
        self.vkindexbuffer = self.mesh.index_buffer;

        // Texture loaded before the descriptor set, since the descriptor needs the sampler/view
        self.textures = try Textures.init(io, render_context.vkcontext.instance, &render_context.vklogicaldevice.handle, render_context.vkphysicaldevice.handle, allocator, "cube", render_context.vklogicaldevice.graphics_family, render_context.vklogicaldevice.graphics_queue);
        errdefer self.textures.deinit(&render_context.vklogicaldevice.handle);

        self.vkdescriptor = try VulkanDescriptor.init(allocator, &render_context.vklogicaldevice.handle, &self.vkuniformbuffer, &self.textures, MAX_FRAMES_IN_FLIGHT);
        errdefer self.vkdescriptor.deinit(&render_context.vklogicaldevice.handle);

        try self.initPipelineAndCommands(io, allocator, render_context);
    }
    pub fn recreateSwapchain(self: *Core, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        _ = render_context.vklogicaldevice.handle.deviceWaitIdle() catch {};
        self.vkcommandbuffer.deinit(&render_context.vklogicaldevice.handle);
        self.vkgraphicspipeline.deinit(&render_context.vklogicaldevice.handle);
        try render_context.recreateSwapchain(allocator);
        try self.initPipelineAndCommands(io, allocator, render_context);
    }
    
    pub fn draw(self: *Core, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext, view: [4][4]f32) !void {
        if (render_context.window.takePendingResize()) |resize| {
            if (resize.width == 0 or resize.height == 0) return; 
            try self.recreateSwapchain(io, allocator, render_context);
            return;
        }
    
        const now = std.Io.Clock.now(.awake, io);
        const elapsed = @as(f32, @floatFromInt(self.start_time.durationTo(now).toNanoseconds())) / 1_000_000_000.0;
        const needs_recreate = try VulkanDraw.draw(
            &render_context.vklogicaldevice.handle,
            render_context.vkswapchain.handle,
            &render_context.vksync,
            render_context.vklogicaldevice.present_queue,
            render_context.vklogicaldevice.graphics_queue,
            &self.vkcommandbuffer,
            render_context.vkframebuffer.handles,
            &self.vkvertexbuffer,
            &self.vkindexbuffer,
            &self.vkuniformbuffer,
            &self.vkdescriptor,
            view,
            elapsed,
        );
        if (needs_recreate) try self.recreateSwapchain(io, allocator, render_context);
    }

    // We love memory and we want it free
    pub fn deinit(self: *Core, render_context: *VulkanRenderContext) void {
        _ = render_context.vklogicaldevice.handle.deviceWaitIdle() catch {};
        self.vkdescriptor.deinit(&render_context.vklogicaldevice.handle);
        self.vkuniformbuffer.deinit(&render_context.vklogicaldevice.handle);
        self.textures.deinit(&render_context.vklogicaldevice.handle);
        self.mesh.deinit(&render_context.vklogicaldevice.handle);
        self.vkcommandbuffer.deinit(&render_context.vklogicaldevice.handle);
        self.vkgraphicspipeline.deinit(&render_context.vklogicaldevice.handle);
    }
};

const std = @import("std");
const glfw = @import("zglfw");
const core = @import("singularity");

const vk = core.vk;
const VulkanRenderContext = core.VulkanRenderContext;
const VulkanGraphicsPipeline = core.VulkanGraphicsPipeline;
const VulkanCommandBuffer = core.VulkanCommandBuffer;
const VulkanVertexBuffer = core.VulkanVertexBuffer;
const VulkanSync = core.VulkanSync;
const cmd = core.VulkanCommand;

pub const Launcher = struct {
    vkgraphicspipeline: VulkanGraphicsPipeline,
    vkcommandbuffer: VulkanCommandBuffer,
    vkvertexbuffer: VulkanVertexBuffer,

    pub fn init(self: *Launcher, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        const vertices = [_]VulkanVertexBuffer.UiVertex{
            .{ .pos = .{ -0.8, -0.8 }, .uv = .{ 0.0, 0.0 } },
            .{ .pos = .{ 0.8, -0.8 }, .uv = .{ 1.0, 0.0 } },
            .{ .pos = .{ 0.8, 0.8 }, .uv = .{ 1.0, 1.0 } },
            .{ .pos = .{ -0.8, -0.8 }, .uv = .{ 0.0, 0.0 } },
            .{ .pos = .{ 0.8, 0.8 }, .uv = .{ 1.0, 1.0 } },
            .{ .pos = .{ -0.8, 0.8 }, .uv = .{ 0.0, 1.0 } },
        };

        self.vkvertexbuffer = try VulkanVertexBuffer.initUi(render_context.vkcontext.instance, render_context.vkphysicaldevice.handle, &render_context.vklogicaldevice.handle, vertices[0..]);
        errdefer self.vkvertexbuffer.deinit(&render_context.vklogicaldevice.handle);

        try self.initPipelineAndCommands(io, allocator, render_context);
    }

    fn initPipelineAndCommands(self: *Launcher, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        self.vkgraphicspipeline = try VulkanGraphicsPipeline.init(io, allocator, &render_context.vklogicaldevice.handle, render_context.vkrenderpass.handle, .{
            .shader_name = "ui",
            .depth_test_enable = false,
            .blend_enable = true,
            .vertex_bindings = &[_]vk.VertexInputBindingDescription{VulkanVertexBuffer.ui_binding},
            .vertex_attributes = VulkanVertexBuffer.ui_attributes[0..],
        });
        errdefer self.vkgraphicspipeline.deinit(&render_context.vklogicaldevice.handle);

        self.vkcommandbuffer = try VulkanCommandBuffer.init(&render_context.vklogicaldevice.handle, render_context.vklogicaldevice.graphics_family, render_context.vkrenderpass.handle, self.vkgraphicspipeline.pipeline, self.vkgraphicspipeline.layout, render_context.vkswapchain.extent);
        errdefer self.vkcommandbuffer.deinit(&render_context.vklogicaldevice.handle);
    }

    pub fn recreateSwapchain(self: *Launcher, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        _ = render_context.vklogicaldevice.handle.deviceWaitIdle() catch {};
        self.vkcommandbuffer.deinit(&render_context.vklogicaldevice.handle);
        self.vkgraphicspipeline.deinit(&render_context.vklogicaldevice.handle);
        try render_context.recreateSwapchain(allocator);
        try self.initPipelineAndCommands(io, allocator, render_context);
    }

    pub fn draw(self: *Launcher, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        const fb_size = render_context.window.handle.getFramebufferSize();
        const fb_w: u32 = @intCast(fb_size[0]);
        const fb_h: u32 = @intCast(fb_size[1]);
        if (fb_w != render_context.vkswapchain.extent.width or fb_h != render_context.vkswapchain.extent.height) {
            try self.recreateSwapchain(io, allocator, render_context);
            return;
        }

        const needs_recreate = try drawUiFrame(
            &render_context.vklogicaldevice.handle,
            render_context.vkswapchain.handle,
            &render_context.vksync,
            render_context.vklogicaldevice.present_queue,
            render_context.vklogicaldevice.graphics_queue,
            &self.vkcommandbuffer,
            render_context.vkframebuffer.handles,
            &self.vkvertexbuffer,
        );
        if (needs_recreate) try self.recreateSwapchain(io, allocator, render_context);
    }

    pub fn run(self: *Launcher, io: std.Io, allocator: std.mem.Allocator, render_context: *VulkanRenderContext) !void {
        while (true) {
            glfw.pollEvents();
            if (render_context.window.handle.shouldClose()) break;
            try self.draw(io, allocator, render_context);
        }
    }

    pub fn deinit(self: *Launcher, render_context: *VulkanRenderContext) void {
        _ = render_context.vklogicaldevice.handle.deviceWaitIdle() catch {};
        self.vkvertexbuffer.deinit(&render_context.vklogicaldevice.handle);
        self.vkcommandbuffer.deinit(&render_context.vklogicaldevice.handle);
        self.vkgraphicspipeline.deinit(&render_context.vklogicaldevice.handle);
    }
};

fn drawUiFrame(logDevice: *const vk.DeviceProxy, swapchain: vk.SwapchainKHR, sync: *VulkanSync, present_queue: vk.Queue, graphics_queue: vk.Queue, command_buffer: *VulkanCommandBuffer, framebuffers: []vk.Framebuffer, vertex_buffer: *VulkanVertexBuffer) !bool {
    const frame = sync.current_frame;
    _ = try logDevice.waitForFences(@ptrCast(&sync.in_flight[frame]), .true, std.math.maxInt(u64));
    const result = logDevice.acquireNextImageKHR(
        swapchain,
        std.math.maxInt(u64),
        sync.image_available[frame],
        .null_handle,
    ) catch |err| {
        if (err == error.OutOfDateKHR) return true;
        return err;
    };
    const image_index = result.image_index;
    try logDevice.resetFences(@ptrCast(&sync.in_flight[frame]));

    var draw_context = cmd.DrawVerticesContext{ .vertex_buffer = vertex_buffer };
    try command_buffer.recordFrame(logDevice, framebuffers[image_index], frame, cmd.drawVerticesContent, &draw_context);

    const wait_stage = vk.PipelineStageFlags{ .color_attachment_output_bit = true };
    try logDevice.queueSubmit(graphics_queue, &[_]vk.SubmitInfo{.{
        .wait_semaphore_count = 1,
        .p_wait_semaphores = @ptrCast(&sync.image_available[frame]),
        .p_wait_dst_stage_mask = @ptrCast(&wait_stage),
        .command_buffer_count = 1,
        .p_command_buffers = @ptrCast(&command_buffer.cmd_buf[frame]),
        .signal_semaphore_count = 1,
        .p_signal_semaphores = @ptrCast(&sync.render_finished[image_index]),
    }}, sync.in_flight[frame]);
    _ = logDevice.queuePresentKHR(present_queue, &.{
        .wait_semaphore_count = 1,
        .p_wait_semaphores = @ptrCast(&sync.render_finished[image_index]),
        .swapchain_count = 1,
        .p_swapchains = @ptrCast(&swapchain),
        .p_image_indices = @ptrCast(&image_index),
    }) catch |err| {
        if (err == error.OutOfDateKHR or err == error.SuboptimalKHR) return true;
        return err;
    };
    sync.current_frame = (sync.current_frame + 1) % core.MAX_FRAMES_IN_FLIGHT;
    return false;
}

const std = @import("std");
const core_mod = @import("core.zig");
const glfw = @import("zglfw");

const State = struct {
    io_threaded: std.Io.Threaded,
    gpa: std.heap.DebugAllocator(.{}),
    render_context: *core_mod.VulkanRenderContext,
    core: *core_mod.Core,
};

var global_state: ?*State = null;

export fn singularity_init() callconv(.c) c_int {
    const state = std.heap.c_allocator.create(State) catch return -1;
    state.gpa = .{};
    const allocator = state.gpa.allocator();

    state.io_threaded = std.Io.Threaded.init(allocator, .{});
    const io = state.io_threaded.io();

    state.render_context = allocator.create(core_mod.VulkanRenderContext) catch {
        state.io_threaded.deinit();
        _ = state.gpa.deinit();
        std.heap.c_allocator.destroy(state);
        return -1;
    };
    state.render_context.init(allocator) catch {
        allocator.destroy(state.render_context);
        state.io_threaded.deinit();
        _ = state.gpa.deinit();
        std.heap.c_allocator.destroy(state);
        return -1;
    };

    state.core = allocator.create(core_mod.Core) catch {
        state.render_context.deinit(allocator);
        allocator.destroy(state.render_context);
        state.io_threaded.deinit();
        _ = state.gpa.deinit();
        std.heap.c_allocator.destroy(state);
        return -1;
    };
    state.core.init(io, allocator, state.render_context) catch {
        allocator.destroy(state.core);
        state.render_context.deinit(allocator);
        allocator.destroy(state.render_context);
        state.io_threaded.deinit();
        _ = state.gpa.deinit();
        std.heap.c_allocator.destroy(state);
        return -1;
    };

    global_state = state;
    return 0;
}

export fn singularity_draw(view: [*c]const f32) callconv(.c) c_int {
    const state = global_state orelse return -1;
    const allocator = state.gpa.allocator();
    const io = state.io_threaded.io();
    const view_mat: [4][4]f32 = @bitCast(view[0..16].*);
    state.core.draw(io, allocator, state.render_context, view_mat) catch return -1;
    return 0;
}

export fn singularity_window_should_close() callconv(.c) c_int {
    const state = global_state orelse return 1;
    return if (state.render_context.window.handle.shouldClose()) 1 else 0;
}

export fn singularity_poll_events() callconv(.c) void {
    glfw.pollEvents();
}

export fn singularity_deinit() callconv(.c) void {
    const state = global_state orelse return;
    const allocator = state.gpa.allocator();
    state.core.deinit(state.render_context);
    allocator.destroy(state.core);
    state.render_context.deinit(allocator);
    allocator.destroy(state.render_context);
    state.io_threaded.deinit();
    _ = state.gpa.deinit();
    std.heap.c_allocator.destroy(state);
    global_state = null;
}

const std = @import("std");
const builtin = @import("builtin");
const vk = @import("../core.zig").vk;
const glfw = @import("../core.zig").glfw;
const BaseWrapper = vk.BaseWrapper;
const InstanceWrapper = vk.InstanceWrapper;

pub extern fn glfwGetInstanceProcAddress(instance: vk.Instance, procname: [*:0]const u8) vk.PfnVoidFunction;

pub const VulkanContext = struct {
    vki: InstanceWrapper,
    instance: vk.InstanceProxy,

    pub fn init() !VulkanContext {
        const vkb = BaseWrapper.load(glfwGetInstanceProcAddress);
        const glfw_extension = try glfw.getRequiredInstanceExtensions();

        const layers = [_][*:0]const u8{"VK_LAYER_KHRONOS_validation"};

        const instance_handle = try vkb.createInstance(&.{
            .p_application_info = &vk.ApplicationInfo{
                .p_application_name = "Singularity Engine",
                .application_version = vk.makeApiVersion(0, 0, 0, 0).toU32(),
                .p_engine_name = "Singularity",
                .engine_version = vk.makeApiVersion(0, 0, 0, 0).toU32(),
                .api_version = vk.API_VERSION_1_4.toU32(),
            },
            .enabled_layer_count = if (builtin.mode == .Debug) 1 else 0,
            .pp_enabled_layer_names = if (builtin.mode == .Debug) &layers else undefined,
            .enabled_extension_count = @intCast(glfw_extension.len),
            .pp_enabled_extension_names = glfw_extension.ptr,
        }, null);

        var self = VulkanContext{
            .vki = InstanceWrapper.load(instance_handle, vkb.dispatch.vkGetInstanceProcAddr orelse return error.MissingProcAddr),
            .instance = undefined,
        };
        self.instance = vk.InstanceProxy.init(instance_handle, &self.vki);
        std.log.info("Vulkan Instance created successfully.", .{});
        return self;
    }

    pub fn deinit(self: *VulkanContext) void {
        self.instance.destroyInstance(null);
        std.log.info("Vulkan Instance Destroyed.", .{});
    }
};

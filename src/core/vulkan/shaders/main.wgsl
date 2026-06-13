struct UBO {
    model: mat4x4<f32>,
    view: mat4x4<f32>,
    proj: mat4x4<f32>,
    light_pos: vec3<f32>,
    _pad: f32,
    light_color: vec3<f32>,
    _pad2: f32,
}

@group(0) @binding(0) var<uniform> ubo: UBO;

struct VertexInput {
    @location(0) pos: vec3<f32>,
    @location(1) color: vec3<f32>,
    @location(2) normal: vec3<f32>,
}

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) world_pos: vec3<f32>,
}

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    let world = ubo.model * vec4<f32>(in.pos, 1.0);
    out.position = ubo.proj * ubo.view * world;
    out.color = in.color;
    out.normal = (ubo.model * vec4<f32>(in.normal, 0.0)).xyz;
    out.world_pos = world.xyz;
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let ambient = 0.1;
    let n = normalize(in.normal);
    let l = normalize(ubo.light_pos - in.world_pos);
    let diff = max(dot(n, l), 0.0);
    let light = ambient + diff * ubo.light_color;
    return vec4<f32>(in.color * light, 1.0);
}

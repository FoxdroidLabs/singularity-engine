struct VertexInput {
    @location(0) pos: vec2<f32>,
    @location(1) uv: vec2<f32>,
}

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.position = vec4<f32>(in.pos, 0.0, 1.0);
    out.uv = in.uv;
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let base = vec3<f32>(0.08, 0.10, 0.16);
    let accent = vec3<f32>(0.22, 0.45, 0.95);
    let color = mix(base, accent, in.uv.x * in.uv.y);
    return vec4<f32>(color, 0.92);
}

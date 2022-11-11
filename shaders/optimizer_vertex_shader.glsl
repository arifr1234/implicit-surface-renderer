#version 300 es
in vec4 position;

in vec2 optimization_min_point;
in vec2 mipmap_resolution;
in uint lod;

flat out uint v_lod;

uniform vec2 extended_resolution;

void main() {
    v_lod = lod;

    vec2 res_pos = 0.5 * position.xy + 0.5;
    res_pos = (res_pos * mipmap_resolution + optimization_min_point) / extended_resolution;
    res_pos = 2. * res_pos - 1.;

    gl_Position = vec4(res_pos, position.zw);
}

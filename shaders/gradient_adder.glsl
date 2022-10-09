uniform ivec2 min_point;
uniform ivec2 previous_min_point;
uniform ivec2 previous_resolution;

out vec4 out_color;

uniform sampler2D gradient;

void main() {
    ivec2 coord = ivec2(gl_FragCoord.xy);

    coord -= min_point;
    coord *= 2;

    bool x_in_range = coord.x + 1 < previous_resolution.x;
    bool y_in_range = coord.y + 1 < previous_resolution.y;

    coord += previous_min_point;

    vec4 res = texelFetch(gradient, coord, 0);

    if(x_in_range)
    {
        res += texelFetch(gradient, coord + ivec2(1, 0), 0);
    }
    if(y_in_range)
    {
        res += texelFetch(gradient, coord + ivec2(0, 1), 0);
    }
    if(x_in_range && y_in_range)
    {
        res += texelFetch(gradient, coord + ivec2(1, 1), 0);
    }

    out_color = res;
}
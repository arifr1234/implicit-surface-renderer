uniform ivec2 min_point;
uniform ivec2 previous_min_point;

out vec4 out_color;

uniform sampler2D gradient;

void main() {
    ivec2 coord = ivec2(gl_FragCoord.xy);

    coord -= min_point;
    coord *= 2;

    coord += previous_min_point;

    float grad = (
        texelFetch(gradient, coord, 0).x + 
        texelFetch(gradient, coord + ivec2(1, 0), 0).x + 
        texelFetch(gradient, coord + ivec2(0, 1), 0).x + 
        texelFetch(gradient, coord + ivec2(1, 1), 0).x
    );

    out_color = vec4(grad, 0., 0., 0.);
}
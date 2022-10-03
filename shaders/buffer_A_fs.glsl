uniform vec2 resolution;
uniform float time;

out vec4 out_color;

uniform sampler2D buffer_A;

#define PI 3.14159265359

void main() {
  vec2 uv = (gl_FragCoord.xy - resolution / 2.) / min(resolution.x, resolution.y);

  vec3 color = vec3(1, 0, 0);

  out_color = vec4(color, 1.);
}
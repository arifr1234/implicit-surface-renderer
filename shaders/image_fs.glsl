uniform vec2 resolution;
uniform float time;
uniform sampler2D buffer_A;

out vec4 out_color;

void main() {
  vec3 color = texelFetch(buffer_A, ivec2(gl_FragCoord.xy), 0).xyz;

  out_color = vec4(color, 1.);
}
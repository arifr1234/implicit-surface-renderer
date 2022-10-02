#version 300 es
precision mediump float;

uniform vec2 resolution;
uniform float time;
uniform sampler2D buffer_A;

out vec4 out_color;

#define PI 3.14

void main() {
  vec3 color = texelFetch(buffer_A, ivec2(gl_FragCoord.xy), 0).xyz;

  float len = color.x;
  float mod_by = 0.1;
  float len_mod = mod(len, mod_by);


  float t = ((len - len_mod) - 1.) * 2. * PI;
  t -= 0.5*PI;
  color = 0.5 * vec3(cos(t), cos(t - 2.*PI/3.), cos(t - 2.*2.*PI/3.)) + 0.5;

  color *= (len - len_mod) / len;

  // color = mix(vec3(0), color, step(0.8 * fwidth(len), abs(mod(len + 0.06, mod_by) - 0.06)));

  out_color = vec4(color, 1.);
}
#version 300 es
precision mediump float;

uniform vec2 resolution;
uniform float time;

out vec4 out_color;

uniform sampler2D buffer_A;

#define PI 3.14

void main() {
  vec2 uv = (gl_FragCoord.xy - resolution / 2.) / min(resolution.x, resolution.y);

  vec3 color = vec3(0);

  float num_points = 30.;
  for(float a = 0.; a < 2.*PI; a += 2.*PI / num_points){
    color += texture(
      buffer_A, 
      gl_FragCoord.xy / resolution
      +
      0.03 * vec2(cos(a), sin(a)) * min(resolution.x, resolution.y) / resolution).xyz;
  }

  color /= num_points;

  color *= 0.97;

  vec2 abs_uv = abs(uv - 0.3 * vec2(2. * cos(time), sin(2. * time)));
  float t = 3.* time;
  vec4 square = vec4(
    vec3(1, 0, 0), 
    step(max(abs_uv.x, abs_uv.y), 0.2)
  );

  if(time == 0.) color = vec3(0);

  color = mix(color, square.xyz, square.a);

  uv = abs((gl_FragCoord.xy - resolution / 2.) / resolution);
  vec4 boundry = vec4(vec3(0, 0, 0), step(0.5 - 0.01, max(uv.x, uv.y)));

  color = mix(color, boundry.xyz, boundry.a);

  out_color = vec4(color, 1.);
}
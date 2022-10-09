uniform float time;
uniform sampler2D optimization_parameters;

out vec4 out_color;

vec4 R_gradient_and_value(vec3 p, R_params params)
{
  dual dr_dx = R(transpose(mat2x3(p, vec3(1, 0, 0))), params);
  dual dr_dy = R(transpose(mat2x3(p, vec3(0, 1, 0))), params);
  dual dr_dz = R(transpose(mat2x3(p, vec3(0, 0, 1))), params);

  return vec4(
    dr_dx.y,
    dr_dy.y,
    dr_dz.y,
    dr_dx.x  // last value is the value of r.
  );
}

void main() {
  scene_params scene = get_scene_params(gl_FragCoord.xy);

  float t = texelFetch(optimization_parameters, ivec2(gl_FragCoord.xy), 0).x;

  vec3 p = t * scene.ray + scene.camera;

  vec4 gradient_and_value = R_gradient_and_value(p, R_params(time));
  vec3 gradient = normalize(gradient_and_value.xyz);
  float r_value = gradient_and_value.w;

  vec3 color = vec3(0);

  vec3 light = normalize(vec3(1, 2, 0));
  float shade = (dot(gradient, -light) + 1.) / 2.;

  float is_zero = smoothstep(-10., 10., r_value); //  1. - smoothstep(0., 1., r_value);

  color = shade * vec3(1., is_zero, 1.);

  out_color = vec4(color, 1.);
}
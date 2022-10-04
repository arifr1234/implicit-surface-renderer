uniform float time;
uniform sampler2D buffer_A;

out vec4 out_color;

vec3 R_gradient(vec3 p, R_params params)
{
  return vec3(
    R(transpose(mat2x3(p, vec3(1, 0, 0))), params).y,
    R(transpose(mat2x3(p, vec3(0, 1, 0))), params).y,
    R(transpose(mat2x3(p, vec3(0, 0, 1))), params).y
  );
}

void main() {
  scene_params scene = get_scene_params(gl_FragCoord.xy);

  float t = texelFetch(buffer_A, ivec2(gl_FragCoord.xy), 0).x;

  vec3 p = t * scene.ray + scene.camera;

  vec3 gradient = R_gradient(p, R_params(time));
  gradient = normalize(gradient);

  vec3 color = vec3(0);

  vec3 light = normalize(vec3(1, 2, 0));
  color = vec3((dot(gradient, light) + 1.) / 2.); 

  color = 0.5 * gradient + 0.5;

  out_color = vec4(color, 1.);
}
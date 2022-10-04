uniform float time;

out vec4 out_color;

uniform sampler2D buffer_A;

#define PI 3.14159265359

// ADAM
#define b1 0.9
#define b2 0.999;

dual loss(dual r, dual t)
{
  return Sq(r) + 0.05 * Sq(t);
}

float loss_partial_derivative(vec3 p, float t, vec3 ray, R_params params)
{
  dual r = R(transpose(mat2x3(p, ray)), params);

  return loss(r, dual(t, 1.)).y;
}

void main() {
  scene_params scene = get_scene_params(gl_FragCoord.xy);

  float t = texelFetch(buffer_A, ivec2(gl_FragCoord.xy), 0).x;

  for(int i = 0; i < 10; i++)
  {
    float d_loss_d_t = loss_partial_derivative(scene.camera + scene.ray * t, t, scene.ray, R_params(time));

    t -= 0.01 * d_loss_d_t;
  }

  out_color = vec4(t, 0, 0, 0);
}
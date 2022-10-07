uniform float time;

uniform float m_hat_normalization;
uniform float v_hat_normalization;

out vec4 out_color;

uniform sampler2D buffer_A;

#define PI 3.14159265359

dual sherable_loss(dual r)
{
  return Sq(r);  // - Div(constant(1.), Sq(r) + constant(0.5));
}

dual t_penalty(dual t)
{
  return 2. * t;
}

float d_sherable_loss_dt(vec3 p, vec3 ray, R_params params)
{
  dual r = R(transpose(mat2x3(p, ray)), params);

  return sherable_loss(r).y;
}

float d_t_penalty_loss_dt(float t)
{
  return t_penalty(dual(t, 1.)).y;
}

void main() {
  scene_params scene = get_scene_params(gl_FragCoord.xy);

  vec4 params = texelFetch(buffer_A, ivec2(gl_FragCoord.xy), 0);
  float t = params.x;
  float m = params.y;
  float v = params.z;

  float grad = (
    d_sherable_loss_dt(scene.camera + scene.ray * t, scene.ray, R_params(time)) + 
    d_t_penalty_loss_dt(t)
  );

  m = b1 * m + (1. - b1) * grad;
  v = b2 * v + (1. - b2) * sq(grad);
  
  float m_hat = m / m_hat_normalization;
  float v_hat = v / v_hat_normalization;
  
  float delta = alpha * m_hat / (sqrt(v_hat) + 1e-8);

  t -= delta;

  out_color = vec4(t, m, v, 0.);
}
uniform float m_hat_normalization;
uniform float v_hat_normalization;

out vec4 out_color;

uniform sampler2D even_gradient;
uniform sampler2D odd_gradient;
uniform sampler2D optimization_parameters;

flat in uint v_lod;

dual t_penalty(dual t)
{
  return 10. * Sq(t);  // 0. * (0. < t.x ? 0.00 * t : -10. * t);
}

float d_t_penalty_loss_dt(float t)
{
  return t_penalty(dual(t, 1.)).y;
}

void main() {
  ivec2 coord = ivec2(gl_FragCoord.xy);

  vec4 params = texelFetch(optimization_parameters, coord, 0);
  float t = params.x;
  float m = params.y;
  float v = params.z;
  
  float grad = d_t_penalty_loss_dt(t);

  switch(v_lod % 2u){
    case 0u:
      grad += texelFetch(even_gradient, coord, 0).x;
      break;
    case 1u:
      grad += texelFetch(odd_gradient, coord, 0).x;
      break;
  }

  m = b1 * m + (1. - b1) * grad;
  v = b2 * v + (1. - b2) * sq(grad);
  
  float m_hat = m / m_hat_normalization;
  float v_hat = v / v_hat_normalization;
  
  float delta = alpha * m_hat / (sqrt(v_hat) + 1e-8);

  t -= delta;

  out_color = vec4(t, m, v, 0.);
}
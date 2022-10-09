uniform float m_hat_normalization;
uniform float v_hat_normalization;

out vec4 out_color;

uniform sampler2D gradient;
uniform sampler2D optimization_parameters;

dual t_penalty(dual t)
{
  return 0.2 * t;
}

float d_t_penalty_loss_dt(float t)
{
  return t_penalty(dual(t, 1.)).y;
}

void main() {
  vec2 shareable_grad = texelFetch(gradient, ivec2(gl_FragCoord.xy), 0).xy;

  if(shareable_grad.y == -1.)
  {
    out_color = vec4(0, 0, 0, -1);
    return;
  }

  vec4 params = texelFetch(optimization_parameters, ivec2(gl_FragCoord.xy), 0);
  float t = params.x;
  float m = params.y;
  float v = params.z;

  float grad = (
    shareable_grad.x + 
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
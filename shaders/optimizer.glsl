uniform float m_hat_normalization;
uniform float v_hat_normalization;

out vec4 out_color;

uniform sampler2D gradient;
uniform sampler2D optimization_parameters;

dual t_penalty(dual t)
{
  return 0. * t;
}

float d_t_penalty_loss_dt(float t)
{
  return t_penalty(dual(t, 1.)).y;
}

void main() {
  // TODO: simple condition to prevent unnesecery executions.
  // a solution may be reading some value from gradient.

  vec4 params = texelFetch(optimization_parameters, ivec2(gl_FragCoord.xy), 0);
  float t = params.x;
  float m = params.y;
  float v = params.z;

  float grad = (
    texelFetch(gradient, ivec2(gl_FragCoord.xy), 0).x + 
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
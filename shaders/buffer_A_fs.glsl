uniform float time;

out vec4 out_color;

uniform sampler2D buffer_A;

#define PI 3.14159265359

// ADAM
#define b1 0.9
#define b2 0.999
#define alpha 0.01
// 0.001

dual sherable_loss(dual r)
{
  return Sq(r) - Div(constant(1.), Sq(r) + constant(0.5)) + 2. * t;  // ADD SEPERATLY, THIS SOULDN'T PROPAGATE.
}

float d_sherable_loss_dt(vec3 p, vec3 ray, R_params params)
{
  dual r = R(transpose(mat2x3(p, ray)), params);

  return sherable_loss(r).y;
}

void main() {
  scene_params scene = get_scene_params(gl_FragCoord.xy);

  vec4 params = texelFetch(buffer_A, ivec2(gl_FragCoord.xy), 0);
  float t = params.x;
  float m = params.y;
  float v = params.z;
  float i = params.w;

  // TODO: Test this (i).
  // TODO: Reset params.
  // TODO: One iteration.

  float initial_i = i;
  for(; i < initial_i + 10.; i++)
  {
    float grad = d_sherable_loss_dt(scene.camera + scene.ray * t, scene.ray, R_params(time));

    m = b1 * m + (1. - b1) * grad;
    v = b2 * v + (1. - b2) * sq(grad);
    
    float m_hat = m / (1. - pow(b1, i));
    float v_hat = v / (1. - pow(b2, i));
    
    float delta = alpha * m_hat / (sqrt(v_hat) + 1e-8);

    t -= delta;
  }

  out_color = vec4(t, m, v, i);
}
uniform float time;

out vec4 out_color;

uniform sampler2D optimization_parameters;

dual shareable_loss(dual r)
{
  return Sq(r);  // - Div(constant(1.), Sq(r) + constant(0.5));
}

float d_shareable_loss_dt(vec3 p, vec3 ray, R_params params)
{
  dual r = R(transpose(mat2x3(p, ray)), params);

  return shareable_loss(r).y;
}

void main() {
  scene_params scene = get_scene_params(gl_FragCoord.xy);

  ivec2 coord = ivec2(gl_FragCoord.xy);

  float t = 0.;

  for(int lod = 0; lod < min_points.length(); lod++)
  {
    t += texelFetch(optimization_parameters, ivec2(min_points[lod]) + coord, 0).x;

    coord /= 2;
  }

  float grad = (
    d_shareable_loss_dt(scene.camera + scene.ray * t, scene.ray, R_params(time))
  );

  out_color = vec4(grad, 0., 0., 0.);  // The value of R can be calculated easily
}
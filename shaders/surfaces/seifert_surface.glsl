#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define cis(a) vec2(cos(a), sin(a))

struct R_params{
  float time;
};

dual R4(dual4 p, R_params params)
{
    dual_complex z = dual_complex(p[0], p[1]);
    dual_complex w = dual_complex(p[2], p[3]);
    
    float period = 12.;
    
    float p_param = 4.;
    float q_param = 4.;
    
    #if 0
      p_param = 5.;
      q_param = 3.;
    #elif 0
      p_param = 3.;
      q_param = 5.;
    #elif 0
      p_param = 3.;
      q_param = 2.;
    #endif

    dual_complex pol = Pow(w, p_param) + Pow(z, q_param);
    
    float angle = 0.;
    #if 0
      angle = (0.5 * sin(params.time * TWO_PI / period) + 1.) * PI;
    #endif
    
    return AbsSq(Normalize(pol) - dual2(constant(cos(angle)), constant(sin(angle))));
}

dual R(dual3 p, R_params params)  // R(p) == 0
{
    //return Sq(p[2]) + Sq(Sqrt(Sq(p[0]) + Sq(p[1])) - constant(1.)) - constant(sq(0.5));
    
    dual s = Sq(p[0]) + Sq(p[1]) + Sq(p[2]);
    
    return R4(
      Div(
        dual4(s - constant(1.), 2.*p[2], 2.*p[0], 2.*p[1]),
        s + constant(1.)
      ), 
      params
    );
}